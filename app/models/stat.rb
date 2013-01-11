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
      if site = ::Site.find_by_token(site_token)
        realtime_stats_active = site.addon_plan_is_active?(AddonPlan.get('stats', 'realtime'))

        if [values[:inc], values[:set], values[:add_to_set]].any? { |v| v.present? }
          if realtime_stats_active
            Stat::Site::Minute.collection.find(t: site_token, d: log.minute).update({ :$inc => values[:inc] }, upsert: true)
            Stat::Site::Hour.collection.find(t: site_token, d: log.hour).update({ :$inc => values[:inc] }, upsert: true)
          end
          Stat::Site::Day.collection.find(t: site_token, d: log.day).update({
            :$inc => values[:inc],
            :$set => values[:set],
            :$addToSet => values[:add_to_set]
          }, upsert: true)
        end

        values[:videos].each do |video_ui, video_inc|
          if video_inc.present?
            begin
              if realtime_stats_active
                Stat::Video::Minute.collection.find(st: site_token, u: video_ui, d: log.minute).update({ :$inc => video_inc }, upsert: true)
                Stat::Video::Hour.collection.find(st: site_token, u: video_ui, d: log.hour).update({ :$inc => video_inc }, upsert: true)
              end
              Stat::Video::Day.collection.find(st: site_token, u: video_ui, d: log.day).update({ :$inc => video_inc }, upsert: true)
            rescue BSON::InvalidStringEncoding
            end
          end
        end
        clean_and_increment_metrics(values)
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
    incs     = Hash.new { |h,k| h[k] = {
      inc: Hash.new(0),
      set: {},
      add_to_set: Hash.new { |h,k| h[k] = { :$each => [] }  },
      videos: Hash.new { |h,k| h[k] = Hash.new(0) }
    } }
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
        if site[:set].present?
          site[:set].each do |set, value|
            incs[site[:t]][:set][set] = value
          end
        end
        if site[:add_to_set].present?
          site[:add_to_set].each do |add_to_set, value|
            incs[site[:t]][:add_to_set][add_to_set][:$each] << value
            incs[site[:t]][:add_to_set][add_to_set][:$each].uniq!
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
      rescue StatRequestParser::BadParamsError, ArgumentError
      rescue TypeError => ex
        Notify.send("Request parsing problem: #{request}", exception: ex)
      end
    end

    incs
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :stats }.categories
  end

  def self.clean_and_increment_metrics(values)
    if values[:inc]
      values[:inc].each do |field, value|
        inc_increment(field, value) if field =~ /^pv\.(m|e|em|d|s|i)$/
      end
      if values[:set]
        if values[:set]['s']
          Librato.increment "stats.page_visits.ssl_per_min", by: 1, source: 'ssl'
        else
          Librato.increment "stats.page_visits.ssl_per_min", by: 1, source: 'non-ssl'
        end
      end
      if values[:add_to_set] && values[:add_to_set]['st'].present?
        values[:add_to_set]['st'][:$each].each do |stage|
          Librato.increment "stats.page_visits.stage_per_min", by: 1, source: key_to_string(:add_to_set, stage)
        end
      else
        Librato.increment "stats.page_visits.stage_per_min", by: 1, source: 'stable'
      end
    end
    values[:videos].values.each do |video_inc|
      if video_inc.present?
        video_inc.each do |field, value|
          inc_increment(field, value)  if field =~ /^(vv|vl)\.(m|e|em|d|s|i)$/
        end
      end
    end
  end

  def self.inc_increment(field, value)
    keys = field.split('.')
    Librato.increment "stats.#{key_to_string(:inc, keys[0])}", by: value, source: key_to_string(:inc, keys[1])
  end

  def self.key_to_string(namespace, key)
    {
      inc: {
        "pv" => "page_visits",
        "vv" => "video_plays",
        "vl" => "video_loads",
        "m"  => "main",
        "e"  => "extra",
        "em" => "embed",
        "d"  => "dev",
        "s"  => "staging",
        "i"  => "invalid"
      },
      add_to_set: {
        "s" => 'stable',
        "b" => 'beta',
        "a" => 'alpha'
      }
    }[namespace][key]
  end

end
