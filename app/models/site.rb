require_dependency 'hostname'
require_dependency 'validators/hostname_validator'
require_dependency 'validators/hostname_uniqueness_validator'
require_dependency 'validators/dev_hostnames_validator'
require_dependency 'validators/extra_hostnames_validator'
require_dependency 'services/sites/loader'
require_dependency 'services/sites/settings'

class Site < ActiveRecord::Base
  include SiteModules::Addon
  include SiteModules::Api
  include SiteModules::Billing
  include SiteModules::Referrer
  include SiteModules::Scope
  include SiteModules::Usage

  DEFAULT_DOMAIN = 'please-edit.me' unless defined?(DEFAULT_DOMAIN)
  DEFAULT_DEV_DOMAINS = '127.0.0.1,localhost' unless defined?(DEFAULT_DEV_DOMAINS)
  PLAYER_MODES = %w[dev beta stable] unless defined?(PLAYER_MODES)

  # Versioning
  has_paper_trail ignore: [
    :last_30_days_main_video_views,
    :last_30_days_extra_video_views, :last_30_days_dev_video_views,
    :last_30_days_invalid_video_views, :last_30_days_embed_video_views,
    :last_30_days_billable_video_views_array, :last_30_days_video_tags
  ]

  acts_as_taggable

  attr_accessor :last_transaction, :remote_ip

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged, :remote_ip

  serialize :last_30_days_billable_video_views_array, Array

  uniquify :token, chars: Array('a'..'z') + Array('0'..'9')


  # FIXME: delegate to addon
  # delegate :stats_retention_days, to: :plan, prefix: true

  # ================
  # = Associations =
  # ================

  belongs_to :user

  # Plans
  belongs_to :plan

  # Invoices
  has_many :invoices, class_name: '::Invoice'
  has_one  :last_invoice, class_name: '::Invoice', order: 'created_at DESC'

  # Addons
  has_many :billable_items, dependent: :destroy do
    def active
      merge(BillableItem.active).scoped
    end

    def subscribed
      merge(BillableItem.subscribed).scoped
    end

    def out_of_trial
      merge(BillableItem.out_of_trial).scoped
    end
  end
  has_many :app_designs, through: :billable_items, source: :item, source_type: 'App::Design'
  has_many :addon_plans, through: :billable_items, source: :item, source_type: 'AddonPlan'
  accepts_nested_attributes_for :billable_items, allow_destroy: true

  has_many :billable_item_activities

  has_many :kits

  # App::Components
  has_many :components, through: :billable_items

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
  def video_tags
    VideoTag.where(st: token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :user,        presence: true
  validates :player_mode, inclusion: PLAYER_MODES

  validates :hostname, hostname: true, hostname_uniqueness: true
  validates :dev_hostnames,   dev_hostnames: true
  validates :extra_hostnames, extra_hostnames: true
  validates :path, length: { maximum: 255 }

  # =============
  # = Callbacks =
  # =============

  before_validation ->(site) do
    site.hostname = DEFAULT_DOMAIN unless hostname?
    site.dev_hostnames = DEFAULT_DEV_DOMAINS unless dev_hostnames?
  end

  # Site::Loader
  after_create ->(site) { Services::Sites::Loader.delay.update_all_modes!(site.id) }
  after_save ->(site) { Services::Sites::Loader.delay.update_all_modes!(site.id) if site.player_mode_changed? }
  # Site::Settings
  after_save ->(site) do
    if (site.changed & Services::Sites::Settings::SITE_FIELDS).present?
      Services::Sites::Settings.delay.update_all_types!(site.id)
      site.touch(:settings_updated_at)
    end
  end

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:archive)   { transition [:active, :suspended] => :archived }
    event(:suspend)   { transition active: :suspended }
    event(:unsuspend) { transition suspended: :active }

    after_transition ->(site) do
      Services::Sites::Loader.delay.update_all_modes!(site.id)
      Services::Sites::Settings.delay.update_all_types!(site.id)
    end

    before_transition on: :archive do |site, transition|
      site.archived_at = Time.now.utc
    end

    after_transition on: :archive do |site, transition|
      site.invoices.not_paid.map(&:cancel)
    end
  end

  def self.to_backbone_json
    all.map(&:to_backbone_json)
  end

  def to_backbone_json(options = {})
    to_json(
      only: [:token, :hostname],
      methods: [:plan_stats_retention_days]
    )
  end

  %w[hostname extra_hostnames dev_hostnames].each do |method_name|
    define_method "#{method_name}=" do |attribute|
      write_attribute(method_name, Hostname.clean(attribute))
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

  def settings_changed?
    (changed & %w[player_mode hostname extra_hostnames dev_hostnames path wildcard badged]).present?
  end

end

# == Schema Information
#
# Table name: sites
#
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
#  created_at                                :datetime         not null
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
#  player_mode                               :string(255)      default("stable")
#  refunded_at                               :datetime
#  settings_updated_at                       :datetime
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
#  index_sites_on_user_id                           (user_id)
#

