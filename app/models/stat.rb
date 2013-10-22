module Stat
  extend ActiveSupport::Concern

  included do
    field :d, type: DateTime

    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Platform { "saf-win" => 2, "saf-osx" => 4, ...}

    index d: 1

    default_scope order_by(d: 1)
  end

  def time
    d.to_i
  end

  def self.realtime_stat_addon
    AddonPlan.get('stats', 'realtime')
  end

  def self.create_stats_from_trackers!(log, trackers)
    tracker_incs = incs_from_trackers(trackers)

    tracker_incs.each do |site_token, values|
      next unless site = ::Site.where(token: site_token).first

      realtime_stats_active = site.subscribed_to?(realtime_stat_addon)

      if [values[:inc], values[:set], values[:add_to_set]].any? { |v| v.present? }
        increment_for_site_token_and_periods(Stat::Site, site_token, [:minute, :hour], log, values[:inc]) if realtime_stats_active

        find_for_site_token_and_period(Stat::Site, site_token, :day, log).update({
          :$inc => values[:inc],
          :$set => values[:set],
          :$addToSet => values[:add_to_set]
        }, upsert: true)
      end

      values[:videos].each do |video_ui, video_inc|
        next unless video_inc.present?

        begin
          periods  = [:day]
          periods += [:minute, :hour] if realtime_stats_active
          increment_for_site_token_and_periods(Stat::Video, site_token, periods, log, video_inc, uid: video_ui)
        rescue BSON::InvalidStringEncoding
        end
      end
      clean_and_increment_metrics(values)
    end

    json = { m: true }
    json[:h] = true if log.hour == log.minute
    json[:d] = true if log.day == log.hour
    PusherWrapper.trigger('stats', 'tick', json)
  end

  def self.find_for_site_token_and_period(klass, site_token, period, log, options = {})
    conditions = { klass.site_token_field => site_token, d: log.send(period) }
    conditions[:u] = options[:uid] if options[:uid]

    klass.const_get(period.to_s.camelize).collection.find(conditions)
  end

  def self.increment_for_site_token_and_periods(klass, site_token, periods, log, incs, options = {})
    periods.each do |period|
      find_for_site_token_and_period(klass, site_token, period, log, options).update({ :$inc => incs }, upsert: true)
    end
  end

  private

  def self.default_incs_hash
    {
      inc: Hash.new(0),
      set: {},
      add_to_set: Hash.new { |h, k| h[k] = { :$each => [] } },
      videos: Hash.new { |h, k| h[k] = Hash.new(0) }
    }
  end

  # Merge each trackers params on one big hash
  #
  # { 'site_token' => { inc: {...}, videos: { 'video_uid' => { inc }, ... } } }
  #
  def self.incs_from_trackers(trackers)
    Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']
    queue = Librato::Metrics::Queue.new
    trackers = only_stats_trackers(trackers)
    incs     = Hash.new { |h, k| h[k] = default_incs_hash }

    trackers.each do |tracker, hits|
      begin
        request, user_agent = tracker
        params     = Addressable::URI.parse(request).query_values.try(:symbolize_keys) || {}

        queue = _increment_temp_metrics(queue, params, hits)

        params_inc = ::StatRequestParser.stat_incs(params, user_agent, hits)

        incs_from_tracker_for_site(params_inc[:site], incs)
        incs_from_tracker_for_videos(params_inc[:videos], incs)
      rescue StatRequestParser::BadParamsError, ArgumentError
      rescue TypeError => ex
        Notifier.send("Request parsing problem: #{request}", exception: ex)
      end
    end
    queue.submit

    incs
  end

  def self._increment_temp_metrics(queue, params, hits)
    case params[:e]
    when 's'
      queue.add "temp.starts.#{_player_version(params)}" => { measure_time: _time(params), value: hits, source: 'old' }
    when 'l'
      vu_size = params[:vu].size
      if vu_size == 0
        Honeybadger.notify(error_message: 'Params vu is empty', parameters: params)
      end
      queue.add "temp.loads.#{_player_version(params)}" => { measure_time: _time(params), value: vu_size * hits, source: 'old' }
    end
  rescue => ex
    Honeybadger.notify(ex, error_message: 'Issue with temp metrics', parameters: params)
  ensure
    queue
  end

  def self._time(params)
    params[:i].to_i / 1000
  end

  def self._player_version(params)
    params.fetch(:v, 'none')
  end

  def self.incs_from_tracker_for_site(site_params_inc, global_incs)
    if site_params_inc[:inc].present?
      site_params_inc[:inc].each do |key, value|
        global_incs[site_params_inc[:t]][:inc][key] += value
      end
    end

    if site_params_inc[:set].present?
      site_params_inc[:set].each do |set, value|
        global_incs[site_params_inc[:t]][:set][set] = value
      end
    end

    if site_params_inc[:add_to_set].present?
      site_params_inc[:add_to_set].each do |add_to_set, value|
        global_incs[site_params_inc[:t]][:add_to_set][add_to_set][:$each] << value
        global_incs[site_params_inc[:t]][:add_to_set][add_to_set][:$each].uniq!
      end
    end
  end

  def self.incs_from_tracker_for_videos(video_params_inc, global_incs)
    video_params_inc.each do |video|
      incs_from_tracker_for_video(video, global_incs) if video[:inc].present?
    end
  end

  def self.incs_from_tracker_for_video(video_params_inc, global_incs)
    video_params_inc[:inc].each do |inc, value|
      global_incs[video_params_inc[:st]][:videos][video_params_inc[:u]][inc] += value
    end
  end

  def self.only_stats_trackers(trackers)
    trackers.find { |t| t.options[:title] == :stats }.categories
  end

  def self.clean_and_increment_metrics(values)
    if values[:inc]
      values[:inc].each do |field, value|
        _increment_librato_for_field(field, value) if field =~ /^pv\.(m|e|em|d|s|i)$/
      end

      if values[:set]
        _increment_librato(event: 'page_visits.ssl_per_min', source: values[:set]['s'] ? 'ssl' : 'non-ssl')
        _increment_librato(event: 'page_visits.jquery', source: values[:set]['jq'] || 'none')
      end

      if values[:add_to_set] && values[:add_to_set]['st'].present?
        values[:add_to_set]['st'][:$each].each do |stage|
          _increment_librato(event: 'page_visits.stage_per_min', source: key_to_string(:add_to_set, stage))
        end
      else
        _increment_librato(event: 'page_visits.stage_per_min', source: 'stable')
      end
    end

    values[:videos].values.each do |video_inc|
      if video_inc.present?
        video_inc.each do |field, value|
          _increment_librato_for_field(field, value) if field =~ /^(vv|vl)\.(m|e|em|d|s|i)$/
        end
      end
    end
  end

  def self.key_to_string(namespace, key)
    {
      inc: {
        'pv' => 'page_visits',
        'vv' => 'video_plays',
        'vl' => 'video_loads',
        'm'  => 'main',
        'e'  => 'extra',
        'em' => 'embed',
        'd'  => 'dev',
        's'  => 'staging',
        'i'  => 'invalid'
      },
      add_to_set: {
        's' => 'stable',
        'b' => 'beta',
        'a' => 'alpha'
      }
    }[namespace][key]
  end

  def self._increment_librato_for_field(field, by)
    keys = field.split('.')
    _increment_librato(event: key_to_string(:inc, keys[0]), by: by, source: key_to_string(:inc, keys[1]))
  end

  def self._increment_librato(options = {})
    options.reverse_merge!(by: 1)

    Librato.increment "stats.#{options[:event]}", by: options[:by], source: options[:source]
  end

end
