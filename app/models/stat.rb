module Stat
  extend ActiveSupport::Concern

  included do

    # DateTime periods
    field :s,  type: DateTime  # Second
    field :m,  type: DateTime  # Minute
    field :h,  type: DateTime  # Hour
    field :d,  type: DateTime  # Day

    # ==========
    # = Scopes =
    # ==========

    %w[s m h d].each do |period|
      scope "#{period}_after".to_sym, lambda { |date| where(period => { "$gte" => date.to_i }).order_by([period.to_sym, :asc]) }
      scope "#{period}_before".to_sym,  lambda { |date| where(period => { "$lte" => date.to_i }).order_by([period.to_sym, :asc]) }
      scope "#{period}_between".to_sym, lambda { |start_date, end_date| where(period => { "$gte" => start_date.to_i, "$lte" => end_date.to_i }).order_by([period.to_sym, :asc]) }
    end

  end

  # ====================
  # = Instance Methods =
  # ====================
  module InstanceMethods

    def time
      (s || m || h || d).to_i
    end

  end

  # =================
  # = Class Methods =
  # =================
  module ClassMethods

  end

  def self.create_stats_from_trackers!(log, trackers)
    tracker_incs = incs_from_trackers(trackers)
    tracker_incs.each do |site_token, values|
      if (site_inc = values[:inc]).present?
        Stat::Site.collection.update({ t: site_token, m: log.minute }, { "$inc" => site_inc }, upsert: true)
        Stat::Site.collection.update({ t: site_token, h: log.hour },   { "$inc" => site_inc }, upsert: true)
        Stat::Site.collection.update({ t: site_token, d: log.day },    { "$inc" => site_inc }, upsert: true)
      end
      values[:videos].each do |video_ui, video_inc|
        if video_inc.present?
          Stat::Video.collection.update({ st: site_token, u: video_ui, m: log.minute }, { "$inc" => video_inc }, upsert: true)
          Stat::Video.collection.update({ st: site_token, u: video_ui, h: log.hour },   { "$inc" => video_inc }, upsert: true)
          Stat::Video.collection.update({ st: site_token, u: video_ui, d: log.day },    { "$inc" => video_inc }, upsert: true)
        end
      end
    end
    # begin
    #   json = {}
    #   json[:h] = true if log.hour == log.minute
    #   json[:d] = true if log.day == log.hour
    #   Pusher["stats"].trigger('tick', json)
    # rescue Pusher::Error => ex
    #   Notify.send("Pusher trigger failed", exception: ex)
    # end
  end

  def self.delay_clear_old_seconds_minutes_and_hours_stats
    unless Delayed::Job.already_delayed?('%Stat%clear_old_seconds_minutes_and_hours_stats%')
      delay(priority: 100, run_at: 1.minutes.from_now).clear_old_seconds_minutes_and_hours_stats
    end
  end

private

  def self.clear_old_seconds_minutes_and_hours_stats
    delay_clear_old_seconds_minutes_and_hours_stats

    { s: 63.seconds, m: 62.minutes, h: 26.hours }.each do |period, value|
      [Stat::Site, Stat::Video].each do |klass|
        klass.send("#{period}_before", value.ago).delete_all
      end
    end
  end

  # Merge each trackers params on one big hash
  #
  # { 'site_token' => { :inc => {...}, :videos => { 'video_uid' => { inc }, ... } } }
  #
  def self.incs_from_trackers(trackers)
    trackers = only_stats_trackers(trackers)
    incs     = Hash.new { |h,k| h[k] = { inc: Hash.new(0), videos: Hash.new { |h,k| h[k] = Hash.new(0) } } }
    trackers.each do |tracker, hits|
      begin
        request, user_agent = tracker
        params     = Addressable::URI.parse(request).query_values.try(:symbolize_keys) || {}
        params_inc = StatRequestParser.stat_incs(params, user_agent, hits)
        # Site
        site = params_inc[:site]
        if site[:inc].present?
          site[:inc].each do |inc, value|
            incs[site[:t]][:inc][inc] += value
          end
        end
        # Videos
        params_inc[:videos].each do |video|
          if video[:inc].present?
            video[:inc].each do |inc, value|
              incs[video[:st]][:videos][video[:u]][inc] += value
            end
          end
        end
      rescue StatRequestParser::BadParamsError
      end
    end
    incs
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :stats }.categories
  end

end
