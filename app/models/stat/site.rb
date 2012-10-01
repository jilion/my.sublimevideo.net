# encoding: utf-8

module Stat::Site
  extend ActiveSupport::Concern
  include Stat

  included do
    field :t, type: String    # Site token

    field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }

    index t: 1, d: 1
  end

  # ====================
  # = Instance Methods =
  # ====================

  def site
    Site.find_by_token(t)
  end

  def token
    read_attribute(:t)
  end

  # only main & extra hostname are counted in charts
  def chart_pv
    pv['m'].to_i + pv['e'].to_i
  end

  # only main & extra hostname are counted in charts
  def chart_vv
    vv['m'].to_i + vv['e'].to_i
  end

  # main & extra hostname, with main & extra embed
  def billable_vv
    chart_vv + vv['em'].to_i
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id']  = time
    json['pv']  = chart_pv unless chart_pv.zero?
    json['vv']  = chart_vv unless chart_vv.zero?
    json['bvv'] = billable_vv if d? && !billable_vv.zero?
    json
  end

  # =================
  # = Class Methods =
  # =================
  module ClassMethods

    def last_30_days_page_visits(token, type = :billable)
      last_30_days_stats(token).sum { |stat|
        case type
        when :main
          stat.pv['m'].to_i
        when :extra
          stat.pv['e'].to_i
        when :dev
          stat.pv['d'].to_i
        when :invalid
          stat.pv['i'].to_i
        when :embed
          stat.pv['em'].to_i
        when :billable
          stat.pv['m'].to_i + stat.pv['e'].to_i + stat.pv['em'].to_i
        end
      }
    end

    def all_time_page_visits(token)
      Rails.cache.fetch "Stat::Site.all_time_page_visits##{token}", expires_in: 1.hour do
        self.where(t: { :$in => Array.wrap(token) }).entries.sum { |stat|
          stat.pv['m'].to_i + stat.pv['e'].to_i + stat.pv['d'].to_i + stat.pv['i'].to_i + stat.pv['em'].to_i
        }
      end
    end

    def last_30_days_stats(token)
      from = 30.days.ago.midnight
      to   = 1.day.ago.end_of_day

      Rails.cache.fetch "Stat::Site.last_30_days_stats##{token}", expires_in: 1.hour do
        self.where(t: { :$in => Array.wrap(token) }).between(d: from..to).entries
      end
    end

    # Returns the sum of all the day usage for the given token(s) (optional) and between the given dates (optional).
    #
    # @option options [String] token a valid site token
    # @option options [Array<String>] token an array of valid site tokens
    # @option options [String] view_type the type of views to fetch. Can be 'vv' (Video Views, default) or 'pv' (Page Visits).
    # @option options [DateTime] from represents the datetime from where returning stats
    # @option options [DateTime] to represents the datetime to where returning stats
    # @option options [String] billable_only if true, return only the sum for billable fields
    #
    # @return [Integer] the sum of views
    #
    def views_sum(options = {})
      options = options.symbolize_keys.reverse_merge(view_type: 'vv', billable_only: false)

      conditions = {}
      conditions[:t] = { :$in => Array.wrap(options[:token]) }        if options[:token]
      conditions.deep_merge!(d: { :$gte => options[:from].midnight }) if options[:from]
      conditions.deep_merge!(d: { :$lte => options[:to].end_of_day }) if options[:to]

      sub_fields = %w[m e em] # billable fields: main, extra and embed
      sub_fields << 'd' unless options[:billable_only] # add dev views if billable_only is false

      fields_to_add = []
      sub_fields.each do |sub_field|
        fields_to_add << "$#{options[:view_type]}.#{sub_field}"
      end

      stats = collection.aggregate([
        { :$match => conditions },
        { :$project => {
            _id: 0,
            t: 1,
            viewTot: { :$add => fields_to_add } } },
        { :$group => {
          _id: '$t',
          viewTotSum: { :$sum => '$viewTot' }, } }
      ])

      stats.sum { |stat| stat['viewTotSum'] }
    end

    # Returns an array of Stat::Site objects.
    #
    # @option options [String] token a valid site token
    # @option options [Array<String>] token an array of valid site tokens
    # @option options [Array<Stat::Site>] stats an array of Stat::Site objects
    # @option options [String] view_type the type of views to fetch. Can be 'vv' (Video Views, default) or 'pv' (Page Visits).
    # @option options [String] period the precision desired, can be 'days' (default), 'hours', 'minutes', 'seconds'
    # @option options [DateTime] from represents the datetime from where returning stats
    # @option options [DateTime] to represents the datetime to where returning stats
    # @option options [Boolean] fill_missing_days when true, missing days will be "filled" with 0 main views
    # @option options [Integer] fill_missing_days missing days will be "filled" with the given value as main views
    #
    # @return [Array<Stat::Site>] an array of Stat::Site objects
    #
    def last_stats(options = {})
      options = options.symbolize_keys.reverse_merge(view_type: 'vv', period: 'days', fill_missing_days: true)

      conditions = {}
      conditions[:t] = { :$in => Array.wrap(options[:token]) } if options[:token]
      conditions.deep_merge!(d: { :$gte => options[:from] }) if options[:from]
      conditions.deep_merge!(d: { :$lte => options[:to] }) if options[:to]
      if options[:demo] && options[:period] == 'days'
        conditions.deep_merge!(d: { :$gte => Time.utc(2011,11,29) }) if options[:from]
      end

      sub_fields = %w[m e em] # billable fields: main, extra and embed
      sub_fields << 'd' unless options[:billable_only] # add dev views if billable_only is false

      stats = if (!options[:token] && !options[:stats]) || (options[:token] && options[:token].is_a?(Array))
        collection.aggregate([
          { :$match => conditions },
          { :$group => sub_fields.inject({}) { |hash, field|
              hash["#{field}Sum"] = { :$sum => "$#{options[:view_type]}.#{field}" }
              hash
            }.merge(_id: '$d') },
          { :$project => {
              _id: 0,
              d: '$_id',
              options[:view_type] => sub_fields.inject({}) { |hash, field|
                hash[field] = "$#{field}Sum"
                hash
              } } },
          { :$sort => { d: 1 } },
        ])
      else
        (options[:stats] || scoped).where(conditions).order_by(d: 1).entries
      end

      if !!options[:fill_missing_days]
        options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0
        fill_missing_values_for_last_stats(stats, options)
      else
        stats
      end
    end

  private

    def fill_missing_values_for_last_stats(stats, options = {})
      options = options.symbolize_keys.reverse_merge(field_to_fill: 'm', missing_days_value: 0)

      if !(options[:from] || options[:to])
        options[:from] = stats.min_by { |s| s['d'] }['d'] || Time.now
        options[:to]   = stats.max_by { |s| s['d'] }['d'] || (Time.now - 1.second)
      end

      filled_stats, step = [], 1.send(options[:period])
      while options[:from] <= options[:to]
        filled_stats << if stats.first.try(:[], 'd') == options[:from]
          stats.shift
        else
          self.new(d: options[:from].to_time, options[:view_type].to_sym => { options[:field_to_fill] => options[:missing_days_value] })
        end
        options[:from] += step
      end

      filled_stats
    end

  end

  def self.json(site_token, options = {})
    options[:from], options[:to] = period_intervals(site_token, options[:period])
    options[:token] = site_token

    json_stats = if options[:from].present? && options[:to].present?
      case options[:period]
      when 'seconds'
        Stat::Site::Second.last_stats(options.merge(fill_missing_days: false))
      when 'minutes'
        Stat::Site::Minute.last_stats(options.merge(fill_missing_days: true))
      when 'hours'
        Stat::Site::Hour.last_stats(options.merge(fill_missing_days: true))
      when 'days'
        Stat::Site::Day.last_stats(options.merge(fill_missing_days: true))
      end
    else
      []
    end

    json_stats.to_json(only: [:bp, :md])
  end

private

  def self.period_intervals(site_token, period)
    case period
    when 'seconds'
      to    = 2.seconds.ago.change(usec: 0).utc
      from  = to - 59.seconds
    when 'minutes'
      site  = ::Site.find_by_token(site_token)
      # FIXME Thibaud: Replace with add-on logic
      # if site.plan_stats_retention_days == 0
      #   to   = nil
      #   from = nil
      # else
      last_minute_stat = Stat::Site::Minute.order_by(d: 1).last
      to   = last_minute_stat.try(:d) || 1.minute.ago.change(sec: 0)
      from = to - 59.minutes
      # end
    when 'hours'
      to   = 1.hour.ago.change(min: 0, sec: 0).utc
      from = to - 23.hours
    when 'days'
      site  = ::Site.find_by_token(site_token)
      stats = Stat::Site::Day.where(t: site_token).order_by(d: 1)
      to    = 1.day.ago.midnight
      # FIXME Thibaud: Replace with add-on logic
      # case site.plan_stats_retention_days
      # when 0
      #   to   = nil
      #   from = nil
      # when nil
      from = [(stats.first.try(:d) || Time.now.utc), to - 364.days].min
      # else
      #   from = to - (site.plan_stats_retention_days - 1).days
      # end
    end

    [from, to]
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
#  settings                                  :hstore
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

