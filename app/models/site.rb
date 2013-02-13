class Site < ActiveRecord::Base
  include SiteModules::BillableItem
  include SiteModules::Api
  include SiteModules::Billing
  include SiteModules::Referrer
  include SiteModules::Usage

  DEFAULT_DOMAIN = 'please-edit.me' unless defined?(DEFAULT_DOMAIN)
  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost' unless defined?(DEFAULT_DEV_DOMAINS)

  # Versioning
  has_paper_trail ignore: [
    :last_30_days_main_video_views,
    :last_30_days_extra_video_views, :last_30_days_dev_video_views,
    :last_30_days_invalid_video_views, :last_30_days_embed_video_views,
    :last_30_days_billable_video_views_array, :last_30_days_video_tags
  ]

  acts_as_taggable

  attr_accessor :last_transaction, :remote_ip

  attr_accessible :hostname, :extra_hostnames, :staging_hostnames, :dev_hostnames, :path, :wildcard, :remote_ip, :default_kit_id

  serialize :last_30_days_billable_video_views_array, Array

  uniquify :token, chars: Array('a'..'z') + Array('0'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :default_kit, class_name: 'Kit'
  belongs_to :plan # legacy
  belongs_to :user
  has_many :video_tags

  # Invoices
  has_many :invoices, class_name: '::Invoice'
  has_one  :last_invoice, class_name: '::Invoice', order: 'created_at DESC'

  # Addons
  has_many :billable_items
  has_many :app_designs, through: :billable_items, source: :item, source_type: 'App::Design'
  has_many :addon_plans, through: :billable_items, source: :item, source_type: 'AddonPlan'
  has_many :addons, through: :addon_plans
  has_many :plugins, through: :addons

  has_many :billable_item_activities, order: 'created_at ASC'

  has_many :kits

  # App::Components
  has_many :app_designs_components, through: :app_designs, source: :component
  has_many :addon_plans_components, through: :addon_plans, source: :components

  def components
    # via_designs = app_designs_components.scoped
    # app_design_ids = [nil] + app_designs.map(&:id)
    # via_addon_plans = addon_plans_components.where{app_plugins.app_design_id.in(app_design_ids)}
    # App::Component.where{id.in(via_designs.select{id})| id.in(via_addon_plans.select{id})}

    # Query via addon_plans is too slow and useless for now
    app_designs_components
  end

  # Mongoid associations
  def usages
    SiteUsage.where(site_id: id)
  end
  def referrers
    ::Referrer.where(token: token)
  end
  def day_stats
    Stat::Site::Day.where(t: token)
  end
  def views
    @views ||= Stat::Site::Day.views_sum(token: token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :user, presence: true
  validates :accessible_stage, inclusion: Stage.stages

  validates :hostname, hostname: true
  validates :dev_hostnames,   dev_hostnames: true
  validates :extra_hostnames, extra_hostnames: true
  validates :staging_hostnames, extra_hostnames: true
  validates :path, length: { maximum: 255 }

  # =============
  # = Callbacks =
  # =============

  before_validation ->(site) do
    site.hostname      = DEFAULT_DOMAIN if site.hostname.blank?
    site.dev_hostnames = DEFAULT_DEV_DOMAINS if site.dev_hostnames.blank?
  end

  # Only when accessible_stage change in admin
  after_save ->(site) do
    if site.accessible_stage_changed?
      # Delay for 5 seconds to be sure that commit transaction is done.
      LoaderGenerator.delay(at: 5.seconds.from_now.to_i).update_all_stages!(site.id, deletable: true)
      SettingsGenerator.delay(at: 5.seconds.from_now.to_i).update_all_types!(site.id)
    end
  end

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:archive)   { transition all - [:archived] => :archived }
    event(:suspend)   { transition all - [:suspended] => :suspended }
    event(:unsuspend) { transition :suspended => :active }

    after_transition ->(site) do
      # Delay for 5 seconds to be sure that commit transaction is done.
      LoaderGenerator.delay(at: 5.seconds.from_now.to_i).update_all_stages!(site.id, deletable: true)
      SettingsGenerator.delay(at: 5.seconds.from_now.to_i).update_all_types!(site.id)
    end

    before_transition :on => :suspend do |site, transition|
      SiteManager.new(site).suspend_billable_items
      Librato.increment 'sites.events', source: 'suspend'
    end

    before_transition :on => :unsuspend do |site, transition|
      SiteManager.new(site).unsuspend_billable_items
      Librato.increment 'sites.events', source: 'unsuspend'
    end

    before_transition :on => :archive do |site, transition|
      raise ActiveRecord::ActiveRecordError.new('Cannot be canceled when non-paid invoices present.') if site.invoices.not_paid.any?

      SiteManager.new(site).cancel_billable_items
      Librato.increment 'sites.events', source: 'archive'
      site.archived_at = Time.now.utc
    end
  end

  # ==========
  # = Scopes =
  # ==========

  # state
  scope :active,       where{ state == 'active' }
  scope :inactive,     where{ state != 'active' }
  scope :suspended,    where{ state == 'suspended' }
  scope :archived,     where{ state == 'archived' }
  scope :not_archived, where{ state != 'archived' }
  # legacy
  scope :refunded,  where{ (state == 'archived') & (refunded_at != nil) }

  # attributes queries
  scope :with_wildcard,              where{ wildcard == true }
  scope :with_path,                  where{ (path != nil) & (path != '') & (path != ' ') }
  scope :with_extra_hostnames,       where{ (extra_hostnames != nil) & (extra_hostnames != '') }
  scope :with_not_canceled_invoices, -> { joins(:invoices).merge(::Invoice.not_canceled) }
  def self.with_addon_plan(full_addon_name)
    addon_plan = AddonPlan.get(*full_addon_name.split('-'))

    includes(:billable_items)
    .where { billable_items.item_type == addon_plan.class.to_s }
    .where { billable_items.item_id == addon_plan.id }
  end

  # addons
  scope :paying,     -> { active.includes(:billable_items).merge(BillableItem.subscribed).merge(BillableItem.paid) }
  scope :paying_ids, -> { active.select("DISTINCT(sites.id)").joins("INNER JOIN billable_items ON billable_items.site_id = sites.id").merge(BillableItem.subscribed).merge(BillableItem.paid) }
  scope :free,       -> { active.includes(:billable_items).where{ id << Site.paying_ids } }

  # admin
  scope :user_id, ->(user_id) { where(user_id: user_id) }

  # sort
  scope :by_hostname,                ->(way = 'asc')  { order("#{quoted_table_name()}.hostname #{way}, #{quoted_table_name()}.token #{way}") }
  scope :by_user,                    ->(way = 'desc') { includes(:user).order("name #{way}, email #{way}") }
  scope :by_state,                   ->(way = 'desc') { order("#{quoted_table_name()}.state #{way}") }
  scope :by_google_rank,             ->(way = 'desc') { where{ google_rank >= 0 }.order("#{quoted_table_name()}.google_rank #{way}") }
  scope :by_alexa_rank,              ->(way = 'desc') { where{ alexa_rank >= 1 }.order("#{quoted_table_name()}.alexa_rank #{way}") }
  scope :by_date,                    ->(way = 'desc') { order("#{quoted_table_name()}.created_at #{way}") }
  scope :by_trial_started_at,        ->(way = 'desc') { order("#{quoted_table_name()}.trial_started_at #{way}") }
  scope :by_last_30_days_video_tags, ->(way = 'desc') { order("#{quoted_table_name()}.last_30_days_video_tags #{way}") }
  scope :by_last_30_days_billable_video_views, ->(way = 'desc') {
    order("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) #{way}")
  }
  scope :with_min_billable_video_views, ->(min) {
    where("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) >= #{min}")
  }
  scope :by_last_30_days_extra_video_views_percentage, ->(way = 'desc') {
    order("CASE WHEN (sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views) > 0
    THEN (sites.last_30_days_extra_video_views / CAST(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views AS DECIMAL))
    ELSE -1 END #{way}")
  }

  def self.search(q)
    joins(:user).where{
      (lower(user.email) =~ lower("%#{q}%")) |
      (lower(user.name) =~ lower("%#{q}%")) |
      (lower(:token) =~ lower("%#{q}%")) |
      (lower(:hostname) =~ lower("%#{q}%")) |
      (lower(:extra_hostnames) =~ lower("%#{q}%")) |
      (lower(:staging_hostnames) =~ lower("%#{q}%")) |
      (lower(:dev_hostnames) =~ lower("%#{q}%"))
    }
  end

  def self.with_page_loads
    fields_to_add = %w[m e em].inject([]) do |array, sub_field|
      array << "$pv.#{sub_field}"; array
    end

    stats = Stat::Site::Day.collection.aggregate([
      { :$project => {
          _id: 0,
          t: 1,
          pvTot: { :$add => fields_to_add } } },
      { :$group => {
        _id: '$t',
        pvTotSum: { :$sum => '$pvTot' }, } }
    ])

    where(token: stats.select { |stat| stat['pvTotSum'] > 0 }.map { |s| s['_id'] })
  end


  def self.to_backbone_json
    all.map(&:to_backbone_json)
  end

  def to_backbone_json(options = {})
    to_json(only: [:token, :hostname])
  end

  %w[hostname extra_hostnames staging_hostnames dev_hostnames].each do |method_name|
    define_method "#{method_name}=" do |attribute|
      write_attribute(method_name, HostnameHandler.clean(attribute))
    end
  end

  def path=(attribute)
    write_attribute :path, attribute.respond_to?(:to_s) ? attribute.to_s.downcase.gsub(/^\/|\/$/, '') : ''
  end

  def to_param
    token
  end

  def unmemoize_all
    unmemoize_all_usages
  end

  # for old loader/license templates
  def player_mode
    accessible_stage == 'alpha' ? "dev" : accessible_stage
  end

end

# == Schema Information
#
# Table name: sites
#
#  accessible_stage                          :string(255)      default("beta")
#  addons_updated_at                         :datetime
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
#  created_at                                :datetime         not null
#  current_assistant_step                    :string(255)
#  default_kit_id                            :integer
#  dev_hostnames                             :text
#  extra_hostnames                           :text
#  first_billable_plays_at                   :datetime
#  first_paid_plan_started_at                :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  google_rank                               :integer
#  hostname                                  :string(255)
#  id                                        :integer          not null, primary key
#  last_30_days_billable_video_views_array   :text
#  last_30_days_dev_video_views              :integer          default(0)
#  last_30_days_embed_video_views            :integer          default(0)
#  last_30_days_extra_video_views            :integer          default(0)
#  last_30_days_invalid_video_views          :integer          default(0)
#  last_30_days_main_video_views             :integer          default(0)
#  last_30_days_video_tags                   :integer          default(0)
#  loaders_updated_at                        :datetime
#  next_cycle_plan_id                        :integer
#  overusage_notification_sent_at            :datetime
#  path                                      :string(255)
#  pending_plan_cycle_ended_at               :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_id                           :integer
#  pending_plan_started_at                   :datetime
#  plan_cycle_ended_at                       :datetime
#  plan_cycle_started_at                     :datetime
#  plan_id                                   :integer
#  plan_started_at                           :datetime
#  refunded_at                               :datetime
#  settings_updated_at                       :datetime
#  staging_hostnames                         :text
#  state                                     :string(255)
#  token                                     :string(255)
#  trial_started_at                          :datetime
#  updated_at                                :datetime         not null
#  user_id                                   :integer
#  wildcard                                  :boolean
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_token                             (token)
#  index_sites_on_user_id                           (user_id)
#

