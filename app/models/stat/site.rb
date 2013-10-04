# encoding: utf-8

module Stat::Site
  extend ActiveSupport::Concern
  include Stat

  included do
    field :t, type: String                  # Site token

    field :pv, type: Hash, default: {}      # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }

    field :st, type: Array, default: []     # Stages used
    field :s, type: Boolean, default: false # SSL used
    field :jq # jQuery version used

    index t: 1, d: 1
  end

  # ====================
  # = Instance Methods =
  # ====================

  def site
    Site.where(token: t).first
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

  def self.site_token_field
    :t
  end


  def self._period_bounds(site_token, period)
    send("_#{period}_bounds", site_token)
  end

  def self._seconds_bounds(site_token)
    to = 2.seconds.ago.change(usec: 0).utc

    [to - 59.seconds, to]
  end

  def self._minutes_bounds(site_token)
    last_minute_stat = Stat::Site::Minute.where(t: site_token).order_by(d: 1).last
    to               = last_minute_stat.try(:d) || 1.minute.ago.change(sec: 0)

    [to - 59.minutes, to]
  end

  def self._hours_bounds(site_token)
    to = 1.hour.ago.change(min: 0, sec: 0).utc

    [to - 23.hours, to]
  end

  def self._days_bounds(site_token)
    stats = Stat::Site::Day.where(t: site_token).order_by(d: 1)
    to    = 1.day.ago.midnight

    [[(stats.first.try(:d) || Time.now.utc), to - 364.days].min, to]
  end

  def self.json(site_token, options = {})
    options[:from], options[:to] = _period_bounds(site_token, options[:period])
    options[:token] = site_token

    json_stats = if options[:from].present? && options[:to].present?
      case options[:period]
      when 'seconds'
        Stat::Site::Second.last_stats(options.merge(fill_missing_days: false))
      when 'minutes', 'hours', 'days'
        Stat::Site.const_get(options[:period].classify).last_stats(options)
      end
    else
      []
    end

    json_stats.to_json(only: [:bp, :md])
  end

  module ClassMethods

    def last_30_days_page_visits(token, type = :billable)
      last_30_days_stats(token).sum do |stat|
        case type
        when :main, :extra, :dev, :invalid
          stat.pv[type.to_s[0]].to_i
        when :embed
          stat.pv['em'].to_i
        when :billable
          stat.pv['m'].to_i + stat.pv['e'].to_i + stat.pv['em'].to_i
        end
      end
    end

    def all_time_page_visits(token)
      Rails.cache.fetch ['Stat::Site.all_time_page_visits', token], expires_in: 1.hour do
        self.where(t: { :$in => Array.wrap(token) }).entries.sum do |stat|
          stat.pv['m'].to_i + stat.pv['e'].to_i + stat.pv['d'].to_i + stat.pv['i'].to_i + stat.pv['em'].to_i
        end
      end
    end

    def last_30_days_stats(token)
      Rails.cache.fetch ['Stat::Site.last_30_days_stats', token], expires_in: 1.hour do
        self.where(t: { :$in => Array.wrap(token) }).between(d: 30.days.ago.midnight..1.day.ago.end_of_day).entries
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

      fields_to_add, map, reduce = _fields_to_add_map_and_reduce_for_query(options)

      stats = collection.aggregate([
        { :$match => _conditions_for_query(options) },
        { :$project => map },
        { :$group => reduce }
      ])

      stats.sum { |stat| fields_to_add.sum { |field| stat["viewTotSum#{field}"] } }
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

      conditions = _conditions_for_query(options)
      if options[:demo] && options[:period] == 'days' && options[:from]
        conditions.deep_merge!(d: { :$gte => Time.utc(2011, 11, 29) })
      end

      stats = if !options[:token] || (options[:token] && options[:token].is_a?(Array))
        map, reduce = { _id: '$d' }, {}
        _hit_types_for_query(options).each do |field|
          map["#{field}Sum"] = { :$sum => "$#{options[:view_type]}.#{field}" }
          reduce[field] = "$#{field}Sum"
        end

        collection.aggregate([
          { :$match => conditions },
          { :$group => map },
          { :$project => { _id: 0, d: '$_id', options[:view_type] => reduce } },
          { :$sort => { d: 1 } }
        ])
      else
        all.where(conditions).order_by(d: 1).entries
      end

      if !!options[:fill_missing_days]
        options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0
        _fill_missing_values_for_last_stats(stats, options)
      else
        stats
      end
    end

    private

    def _hit_types_for_query(options)
      hit_types = %w[m e em] # billable fields: main, extra and embed
      hit_types << 'd' unless options[:billable_only] # add dev views if billable_only is false

      hit_types
    end

    def _fields_to_add_map_and_reduce_for_query(options)
      fields_to_add, map, reduce = [], { _id: 0, t: 1 }, { _id: '$t' }

      _hit_types_for_query(options).each do |hit_type|
        field = "#{options[:view_type]}#{hit_type}"
        map["viewTot#{field}"] = { :$add => ["$#{options[:view_type]}.#{hit_type}"] }
        reduce["viewTotSum#{field}"] = { :$sum => "$viewTot#{field}" }
        fields_to_add << field
      end

      [fields_to_add, map, reduce]
    end

    def _conditions_for_query(options)
      conditions = {}
      conditions[:t] = { :$in => Array.wrap(options[:token]) }        if options[:token]
      conditions.deep_merge!(d: { :$gte => options[:from] }) if options[:from]
      conditions.deep_merge!(d: { :$lte => options[:to] }) if options[:to]

      conditions
    end

    def _fill_missing_values_for_last_stats(stats, options = {})
      options = options.symbolize_keys.reverse_merge(field_to_fill: 'm', missing_days_value: 0)

      return stats unless !!options[:fill_missing_days]

      options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0

      if !options[:from] && !options[:to]
        options[:from] = stats.min_by { |s| s['d'] }['d'] || Time.now
        options[:to]   = stats.max_by { |s| s['d'] }['d'] || (Time.now - 1.second)
      end

      filled_stats, step = [], 1.send(options[:period])
      while options[:from] <= options[:to]
        filled_stats << if stats.first.try(:[], 'd') == options[:from]
          stats.shift
        else
          new(d: options[:from].to_time, options[:view_type].to_sym => { options[:field_to_fill] => options[:missing_days_value] })
        end
        options[:from] += step
      end

      filled_stats
    end

  end
end

# == Schema Information
#
# Table name: sites
#
#  accessible_stage          :string(255)      default("beta")
#  addons_updated_at         :datetime
#  alexa_rank                :integer
#  archived_at               :datetime
#  badged                    :boolean
#  created_at                :datetime
#  current_assistant_step    :string(255)
#  default_kit_id            :integer
#  dev_hostnames             :text
#  extra_hostnames           :text
#  first_admin_starts_on     :datetime
#  google_rank               :integer
#  hostname                  :string(255)
#  id                        :integer          not null, primary key
#  last_30_days_admin_starts :integer          default(0)
#  last_30_days_starts       :integer          default(0)
#  last_30_days_starts_array :integer          default([])
#  last_30_days_video_tags   :integer          default(0)
#  loaders_updated_at        :datetime
#  path                      :string(255)
#  plan_id                   :integer
#  refunded_at               :datetime
#  settings_updated_at       :datetime
#  staging_hostnames         :text
#  state                     :string(255)
#  token                     :string(255)
#  updated_at                :datetime
#  user_id                   :integer
#  wildcard                  :boolean
#
# Indexes
#
#  index_sites_on_created_at                       (created_at)
#  index_sites_on_first_admin_starts_on            (first_admin_starts_on)
#  index_sites_on_hostname                         (hostname)
#  index_sites_on_id_and_state                     (id,state)
#  index_sites_on_last_30_days_admin_starts        (last_30_days_admin_starts)
#  index_sites_on_plan_id                          (plan_id)
#  index_sites_on_token                            (token)
#  index_sites_on_user_id                          (user_id)
#  index_sites_on_user_id_and_last_30_days_starts  (user_id,last_30_days_starts)
#

