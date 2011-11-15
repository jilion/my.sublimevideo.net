class Stat::Video
  include Mongoid::Document
  include Stat
  store_in :video_stats

  field :st, type: String # Site token
  field :u,  type: String # Video uid

  field :vl, type: Hash, default: {} # Video Loads: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}
  field :vs, type: Hash, default: {} # Video Sources View { '5062d010' (video source crc32) => 32, ... }

  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

  # ====================
  # = Instance Methods =
  # ====================

  def site
    Site.find_by_token(st)
  end

  def site_token
    read_attribute(:st)
  end

  def uid
    read_attribute(:u)
  end

  # only main & extra hostname are counted in charts
  def chart_vl
    vl['m'].to_i + vl['e'].to_i
  end

  # only main & extra hostname are counted in charts
  def chart_vv
    vv['m'].to_i + vv['e'].to_i
  end

  # =================
  # = Class Methods =
  # =================


  # Returns the sum of all the usage for the given token(s) (optional) and between the given dates (optional).
  #
  # @option site_token [String] a valid site token
  # @option options [String] period, a time period. Can be 'days', 'hours', 'minutes' or 'seconds'
  # @option options [String] view_type, the type of views to order with. Can be 'vv' (Video Views, default) or 'vl' (Video load).
  # @option options [Integer] limit, number of videos to return
  # @option options [String] sort_by, field to sort with
  #
  # @return [Hash] with an array of video hash with video tag metadata and period 'vl' & 'vv' totals + vv period array, the total amount of videos viewed or loaded during the period and the start_time of the period
  #
  def self.top_videos(site_token, options = {})
    from, to   = period_intervals(site_token, options[:period]) unless options[:from] || options[:to]
    options    = options.symbolize_keys.reverse_merge(period: 'days', sort_by: 'vv', limit: 5, from: from, to: to)
    period_sym = options[:period].first.to_sym
    options[:from], options[:to] = options[:from].to_i, options[:to].to_i

    conditions = { st: site_token, period_sym => { "$gte" => Time.at(options[:from]), "$lte" => Time.at(options[:to]) } }

    videos = collection.group(
      key: :u,
      cond: conditions,
      initial: { vv_sum: 0, vl_sum: 0, vv_hash: {}, vl_hash: {} },
      reduce: js_reduce_for_sum(period_sym)
    )

    # replace u per id for Backbone
    videos.each { |video| video["id"] = video.delete("u") }

    total = videos.size

    videos.sort_by! { |video| video["#{options[:sort_by]}_sum"] }.reverse! unless period_sym == :s

    limit  = options[:period] == 'seconds' ? 30 : options[:limit].to_i
    videos = videos.take(limit)

    add_video_tags_metadata!(site_token, videos)
    fill_missing_values!(videos, options)
    { videos: videos, total: total }.merge(options.slice(:period, :from, :to, :sort_by, :limit))
  end

private

  def self.js_reduce_for_sum(period_sym)
    fields = %w[m e] # billable fields: main, extra
    reduce_function = ["function(doc, prev) {"]
    fields.inject(reduce_function) do |js, field_to_merge|
      js << "vl_#{field_to_merge} = doc.vl ? (isNaN(doc.vl.#{field_to_merge}) ? 0 : doc.vl.#{field_to_merge}) : 0;"
      js << "vv_#{field_to_merge} = doc.vv ? (isNaN(doc.vv.#{field_to_merge}) ? 0 : doc.vv.#{field_to_merge}) : 0;"
      js << "prev.vv_sum += vv_#{field_to_merge};" if period_sym != :s
      js << "prev.vl_sum += vl_#{field_to_merge};" if period_sym != :s
      js
    end
    reduce_function << "prev.vv_hash[doc.#{period_sym}.getTime() / 1000] = vv_m + vv_e;"
    reduce_function << "prev.vl_hash[doc.#{period_sym}.getTime() / 1000] = vl_m + vl_e;" if period_sym == :s

    (reduce_function << "}").join(' ')
  end

  def self.add_video_tags_metadata!(site_token, videos)
    video_uids = videos.map { |video| video["id"] }

    VideoTag.where(st: site_token, u: { "$in" => video_uids }).entries.each do |video_tag|
      video = videos.detect { |video| video["id"] == video_tag.u }
      video.merge!(video_tag.meta_data)
    end

    videos
  end

  def self.fill_missing_values!(videos, options = {})
    step = 1.send(options[:period])
    period_is_seconds = options[:period] == 'seconds'
    videos.each do |video|
      video["vv_array"] = []
      video["vl_array"] = [] if period_is_seconds
      from_step = options[:from]
      while from_step <= options[:to]
        video["vv_array"] << video["vv_hash"][from_step.to_s].to_i
        video["vl_array"] << video["vl_hash"][from_step.to_s].to_i if period_is_seconds
        from_step += step
      end
      video.delete("vv_hash")
      if period_is_seconds
        video.delete("vv_sum")
        video.delete("vl_sum")
        video.delete("vl_hash")
      end
    end
  end


end
