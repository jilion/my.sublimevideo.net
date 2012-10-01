# encoding: utf-8
require_dependency 'pusher_wrapper'
require_dependency 'notify'

module Stat
  extend ActiveSupport::Concern

  included do
    field :d, type: DateTime

    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}

    index d: 1

    default_scope order_by(d: 1)
  end

  def time
    d.to_i
  end

  def self.create_stats_from_trackers!(log, trackers)
    tracker_incs = incs_from_trackers(trackers)
    tracker_incs.each do |site_token, values|
      site = ::Site.where(token: site_token).first

      next unless site.addon_is_active?(Addons::Addon.get('stats', 'standard'))

      if (site_inc = values[:inc]).present?
        # FIXME: Replace 'unless site.in_free_plan?' with 'if stats add-on is active'
        Stat::Site::Minute.collection.find(t: site_token, d: log.minute).update({ :$inc => site_inc }, upsert: true)
        Stat::Site::Hour.collection.find(t: site_token, d: log.hour).update({ :$inc => site_inc }, upsert: true)
        Stat::Site::Day.collection.find(t: site_token, d: log.day).update({ :$inc => site_inc }, upsert: true)
      end

      values[:videos].each do |video_ui, video_inc|
        if video_inc.present?
          begin
            # FIXME: Replace 'unless site.in_free_plan?' with 'if stats add-on is active'
            Stat::Video::Minute.collection.find(st: site_token, u: video_ui, d: log.minute).update({ :$inc => video_inc }, upsert: true)
            Stat::Video::Hour.collection.find(st: site_token, u: video_ui, d: log.hour).update({ :$inc => video_inc }, upsert: true)
            Stat::Video::Day.collection.find(st: site_token, u: video_ui, d: log.day).update({ :$inc => video_inc }, upsert: true)
          rescue BSON::InvalidStringEncoding
          end
        end
      end
    end

    json = { m: true }
    json[:h] = true if log.hour == log.minute
    json[:d] = true if log.day == log.hour
    PusherWrapper.trigger('stats', 'tick', json)
  end

private

  # Merge each trackers params on one big hash
  #
  # { 'site_token' => { inc: {...}, videos: { 'video_uid' => { inc }, ... } } }
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
        Notify.send("Request parsing problem: #{request}", exception: ex)
      end
    end

    incs
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :stats }.categories
  end

end
