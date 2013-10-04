require 'searchable'

class Site < ActiveRecord::Base
  include SiteModules::BillableItem
  include SiteModules::Billing
  include SiteModules::Referrer
  include SiteModules::Usage
  include Searchable

  DEFAULT_DOMAIN = 'please-edit.me'
  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'

  # Versioning
  has_paper_trail ignore: [
    :last_30_days_main_video_views,
    :last_30_days_extra_video_views, :last_30_days_dev_video_views,
    :last_30_days_invalid_video_views, :last_30_days_embed_video_views,
    :last_30_days_billable_video_views_array, :last_30_days_video_tags
  ]

  acts_as_taggable

  attr_accessor :last_transaction, :remote_ip

  serialize :last_30_days_billable_video_views_array, Array

  uniquify :token, chars: Array('a'..'z') + Array('0'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :default_kit, class_name: 'Kit'
  belongs_to :plan # legacy
  belongs_to :user

  # Invoices
  has_many :invoices, class_name: '::Invoice'
  has_one  :last_invoice, -> { order(created_at: :desc) }, class_name: '::Invoice'

  # Addons
  has_many :billable_items
  has_many :designs, through: :billable_items, source: :item, source_type: 'Design'
  has_many :addon_plans, through: :billable_items, source: :item, source_type: 'AddonPlan'
  has_many :addons, through: :addon_plans
  has_many :plugins, through: :addons

  has_many :billable_item_activities, -> { order('billable_item_activities.created_at ASC') }

  has_many :kits

  # App::Components
  has_many :designs_components, through: :designs, source: :component
  has_many :addon_plans_components, through: :addon_plans, source: :components

  def components
    # Query via addon_plans is too slow and useless for now
    designs_components
  end

  def referrers
    Referrer.where(token: token)
  end

  def day_stats
    Stat::Site::Day.where(t: token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :user, presence: true
  validates :accessible_stage, inclusion: Stage.stages

  validates :hostname, hostname: true
  validates :dev_hostnames, dev_hostnames: true
  validates :extra_hostnames, :staging_hostnames, extra_hostnames: true
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
    site.delay_update_loaders_and_settings if site.accessible_stage_changed?
  end

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:archive)   { transition all - [:archived] => :archived }
    event(:suspend)   { transition all - [:suspended] => :suspended }
    event(:unsuspend) { transition suspended: :active }

    after_transition ->(site) do
      site.delay_update_loaders_and_settings
    end

    before_transition on: :suspend do |site, transition|
      SiteManager.new(site).suspend_billable_items
      Librato.increment 'sites.events', source: 'suspend'
    end

    before_transition on: :unsuspend do |site, transition|
      SiteManager.new(site).unsuspend_billable_items
      Librato.increment 'sites.events', source: 'unsuspend'
    end

    before_transition on: :archive do |site, transition|
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
  scope :active,       -> { where(state: 'active') }
  scope :suspended,    -> { where(state: 'suspended') }
  scope :archived,     -> { where(state: 'archived') }
  scope :not_archived, -> { where.not(state: 'archived') }

  # attributes queries
  scope :with_wildcard,              -> { where(wildcard: true) }
  scope :with_path,                  -> { where.not(path: [nil, '', ' ']) }
  scope :with_extra_hostnames,       -> { where.not(extra_hostnames: [nil, '']) }
  scope :with_not_canceled_invoices, -> { joins(:invoices).merge(::Invoice.not_canceled) }
  scope :without_hostnames,          ->(hostnames = []) { where.not(hostname: [nil, ''] + hostnames) }

  class << self
    %w[created_on first_billable_plays_on_week].each do |method_name|
      define_method(method_name) do |timestamp|
        timestamp = Time.parse(timestamp) if timestamp.is_a?(String)
        attr_name = method_name.sub(/_on.*/, '_at')
        timerange = method_name =~ /week/ ? timestamp.all_week : timestamp.all_day
        where(:"#{attr_name}" => timerange)
      end
    end
  end

  scope :created_after, ->(timestamp) do
    timestamp = Time.parse(timestamp) if timestamp.is_a?(String)
    where('sites.created_at > ?', timestamp)
  end

  scope :not_tagged_with, ->(tag) do
    tagged_with(tag, exclude: true).references(:taggings)
  end

  # addons
  scope :paying, -> { active.joins(:billable_items).where(billable_items: { state: 'subscribed' }).merge(BillableItem.paid) }
  scope :free,   -> { active.includes(:billable_items).where.not(id: Site.paying.pluck(:id)) }
  scope :with_addon_plan, ->(full_addon_name) {
    addon_plan = AddonPlan.get(*full_addon_name.split('-'))
    active.joins(:billable_items).merge(BillableItem.with_item(addon_plan))
  }

  # admin
  scope :user_id, ->(user_id) { where(user_id: user_id) }

  # sort
  scope :by_hostname,                ->(way = 'asc')  { order("#{quoted_table_name()}.hostname #{way}, #{quoted_table_name()}.token #{way}") }
  scope :by_user,                    ->(way = 'desc') { includes(:user).order("name #{way}, email #{way}") }
  scope :by_state,                   ->(way = 'desc') { order("#{quoted_table_name()}.state #{way}") }
  scope :by_date,                    ->(way = 'desc') { order("#{quoted_table_name()}.created_at #{way}") }
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

  def self.additional_or_conditions(q)
    %w[token hostname extra_hostnames staging_hostnames dev_hostnames].reduce([]) do |a, e|
      a << ("#{e} ILIKE '%#{q}%'")
    end
  end

  def self.with_page_loads_in_the_last_30_days
    stats = Stat::Site::Day.collection.aggregate([
      { :$match => { d: { :$gte => 30.days.ago.midnight } } },
      { :$project => {
          _id: 0,
          t: 1,
          pvmTot: { :$add => '$pv.m' },
          pveTot: { :$add => '$pv.e' },
          pvemTot: { :$add => '$pv.em' } } },
      { :$group => {
        _id: '$t',
        pvmTotSum: { :$sum => '$pvmTot' },
        pveTotSum: { :$sum => '$pveTot' },
        pvemTotSum: { :$sum => '$pvemTot' } } }
    ])
    where(token: stats.select { |stat| (stat['pvmTotSum'] + stat['pveTotSum'] + stat['pvemTotSum']) > 0 }.map { |s| s['_id'] })
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

  def production_hostnames
    [hostname, extra_hostnames.to_s.split(/,\s*/)].flatten
  end

  def to_param
    token
  end

  def views
    @views ||= Stat::Site::Day.views_sum(token: token)
  end

  def delay_update_loaders_and_settings
    # Delay for 5 seconds to be sure that commit transaction is done.
    LoaderGenerator.delay(queue: 'my', at: 5.seconds.from_now.to_i).update_all_stages!(id, deletable: true)
    SettingsGenerator.delay(queue: 'my', at: 5.seconds.from_now.to_i).update_all!(id)
  end

end

# == Schema Information
#
# Table name: sites
#
#  accessible_stage                        :string(255)      default("beta")
#  addons_updated_at                       :datetime
#  alexa_rank                              :integer
#  archived_at                             :datetime
#  badged                                  :boolean
#  created_at                              :datetime
#  current_assistant_step                  :string(255)
#  default_kit_id                          :integer
#  dev_hostnames                           :text
#  extra_hostnames                         :text
#  first_billable_plays_at                 :datetime
#  google_rank                             :integer
#  hostname                                :string(255)
#  id                                      :integer          not null, primary key
#  last_30_days_billable_video_views_array :text
#  last_30_days_dev_video_views            :integer          default(0)
#  last_30_days_embed_video_views          :integer          default(0)
#  last_30_days_extra_video_views          :integer          default(0)
#  last_30_days_invalid_video_views        :integer          default(0)
#  last_30_days_main_video_views           :integer          default(0)
#  last_30_days_video_tags                 :integer          default(0)
#  loaders_updated_at                      :datetime
#  path                                    :string(255)
#  plan_id                                 :integer
#  refunded_at                             :datetime
#  settings_updated_at                     :datetime
#  staging_hostnames                       :text
#  state                                   :string(255)
#  token                                   :string(255)
#  updated_at                              :datetime
#  user_id                                 :integer
#  wildcard                                :boolean
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_id_and_state                      (id,state)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_token                             (token)
#  index_sites_on_user_id                           (user_id)
#

