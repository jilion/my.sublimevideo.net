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
  # @option period [String] a time period. Can be 'days', 'hours', 'minutes' or 'seconds'
  # @option options [String] view_type the type of views to order with. Can be 'vv' (Video Views, default) or 'vl' (Video load).
  # @option options [String] count number of videos to return
  #
  # @return [Array] an array of video hash with video tag metadata and period 'vl' & 'vv' totals + vv period array
  #
  def self.top_videos(site_token, period, options = {})
    from, to   = period_intervals(site_token, period)
    period_sym = period.first.to_sym
    options    = options.symbolize_keys.reverse_merge(view_type: 'vv', count: 10)

    conditions = { st: site_token, period_sym => { "$gte" => from, "$lte" => to } }

    stats = collection.group(
      key: :u,
      cond: conditions,
      initial: { vv_sum: 0, vl_sum: 0, vv_hash: {} },
      reduce: js_reduce_for_sum(period_sym)
    )

    stats.sort_by! { |stat| stat["#{options[:view_type]}_sum"] }.reverse!
    stats = stats.take(options[:count])

    add_video_tags_metadata!(site_token, stats)
    add_vv_array!(stats)

    stats
  end

private

  def self.js_reduce_for_sum(period_sym)
    fields = %w[m e] # billable fields: main, extra
    reduce_function = ["function(doc, prev) {"]
    fields.inject(reduce_function) do |js, field_to_merge|
      js << "vv = isNaN(doc.vv.#{field_to_merge}) ? 0 : doc.vv.#{field_to_merge};"
      js << "prev.vv_sum += vv;"
      js << "prev.vl_sum += isNaN(doc.vl.#{field_to_merge}) ? 0 : doc.vl.#{field_to_merge};"
      js << "prev.vv_hash[doc.#{period_sym}.getTime() / 1000] = vv;"
      js
    end

    (reduce_function << "}").join(' ')
  end

  def self.add_video_tags_metadata!(site_token, stats)
    video_uids = stats.map { |stat| stat["u"] }

    VideoTag.where(st: site_token, u: { "$in" => video_uids }).entries.each do |video_tag|
      stat = stats.detect { |stat| stat["u"] == video_tag.u }
      stat.merge!(video_tag.meta_data)
    end

    stats
  end

  def self.add_vv_array!(stats)
    stats
  end

end
