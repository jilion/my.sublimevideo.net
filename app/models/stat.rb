# encoding: utf-8

module Stat
  extend ActiveSupport::Concern

  included do
    field :d, type: DateTime

    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}

    index :d

    scope :after,   lambda { |date| where(d: { "$gte" => date.to_i }).order_by([:d, :asc]) }
    scope :before,  lambda { |date| where(d: { "$lte" => date.to_i }).order_by([:d, :asc]) }
    scope :between, lambda { |start_date, end_date| where(d: { "$gte" => start_date.to_i, "$lte" => end_date.to_i }).order_by([:d, :asc]) }
  end

  def time
    d.to_i
  end

  def self.create_stats_from_trackers!(log, trackers)
    tracker_incs = incs_from_trackers(trackers)
    tracker_incs.each do |site_token, values|
      site = ::Site.where(token: site_token).includes(:plan).first

      if (site_inc = values[:inc]).present?
        Stat::Site::Minute.collection.update({ t: site_token, d: log.minute }, { "$inc" => site_inc }, upsert: true) unless site.in_free_plan?
        Stat::Site::Hour.collection.update({ t: site_token, d: log.hour },   { "$inc" => site_inc }, upsert: true)
        Stat::Site::Day.collection.update({ t: site_token, d: log.day },    { "$inc" => site_inc }, upsert: true)
      end

      values[:videos].each do |video_ui, video_inc|
        if video_inc.present?
          Stat::Video::Minute.collection.update({ st: site_token, u: video_ui, d: log.minute }, { "$inc" => video_inc }, upsert: true) unless site.in_free_plan?
          Stat::Video::Hour.collection.update({ st: site_token, u: video_ui, d: log.hour },   { "$inc" => video_inc }, upsert: true)
          Stat::Video::Day.collection.update({ st: site_token, u: video_ui, d: log.day },    { "$inc" => video_inc }, upsert: true)
        end
      end
    end

    begin
      json = { m: true }
      json[:h] = true if log.hour == log.minute
      json[:d] = true if log.day == log.hour
      Pusher["stats"].trigger('tick', json)
    rescue Pusher::Error => ex
      Notify.send("Pusher trigger failed", exception: ex)
    end
  end

private

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
      rescue TypeError => ex
        Notify.send("Request parsing problem: #{request}", :exception => ex)
      end
    end

    incs
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :stats }.categories
  end

end
