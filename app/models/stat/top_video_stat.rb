module Stat::TopVideoStat
  extend ActiveSupport::Concern

  included do
    field :d,  type: DateTime  # Second / Minute / Hour / Day
    field :st, type: String # Site token
    field :u,  type: String # Video uid

    field :vl, type: Integer, default: 0 # Billable video loads
    field :vv, type: Integer, default: 0 # Billable video views

    index :d
    index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
    index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

    scope "after".to_sym, lambda { |date| where(d: { "$gte" => date.to_i }) }
    scope "before".to_sym,  lambda { |date| where(d: { "$lte" => date.to_i }) }
    scope "between".to_sym, lambda { |start_date, end_date| where(d: { "$gte" => start_date.to_i, "$lte" => end_date.to_i }) }
  end

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
    options[:from], options[:to] = options[:from].to_i, options[:to].to_i
    options    = options.symbolize_keys.reverse_merge(period: 'days', sort_by: 'vv', limit: 5)
    site_token = SiteToken.www if site_token == 'demo'
    conditions = { st: site_token, d: { "$gte" => Time.at(options[:from]), "$lte" => Time.at(options[:to]) } }

    video_uids, total = top_video_uids(conditions, options)
    videos            = videos_with_tags_metadata(site_token, video_uids)
    add_video_stats_data!(videos, video_uids, conditions, options)
    # Resort with real sum data
    videos.sort_by! { |video| video["#{options[:sort_by]}_sum"] }.reverse!

    { videos: videos, total: total }.merge(options.slice(:period, :from, :to, :sort_by, :limit))
  end

private

  def self.top_video_class(period)
    case period
    when 'seconds' then Stat::TopVideoSecondStat
    when 'minutes' then Stat::TopVideoMinuteStat
    when 'hours'   then Stat::TopVideoHourStat
    when 'days'    then Stat::TopVideoDayStat
    end
  end

  def self.top_video_uids(conditions, options)
    # Demo Page
    if conditions[:st] == SiteToken.www
      conditions[:u]  = { "$in" => %w[home features-lightbox features-playlist-1 features-playlist-2 features-playlist-3 features-playlist-4 demo-single demo-lightbox-1 demo-lightbox-2 demo-lightbox-3 demo-lightbox-4 demo-playlist-1 demo-playlist-2 demo-playlist-3 demo-playlist-4] }
    end

    # Reduce number of stats to group if too many.
    if %w[hours days].include?(options[:period])
      stats_count = top_video_class(options[:period]).where(conditions).count

      if stats_count >= 20_000
        conditions['vl'] = { "$gte" => stats_count / 20_000 }
      end
    end

    videos = top_video_class(options[:period]).collection.group(
      key: :u,
      cond: conditions,
      initial: { "#{options[:sort_by]}_sum" => 0 },
      reduce: "function(doc, prev) { prev.#{options[:sort_by]}_sum += doc.#{options[:sort_by]} }"
    )
    videos.sort_by! { |video| video["#{options[:sort_by]}_sum"] }.reverse!

    total = videos.size

    # Seconds top videos stats will be update real-time so we need more that the limit
    limit  = options[:period] == 'seconds' ? 40 : options[:limit].to_i
    videos = videos.take(limit)

    [videos.map { |v| v["u"] }, total]
  end

  def self.videos_with_tags_metadata(site_token, video_uids)
    video_tags = VideoTag.where(st: site_token, u: { "$in" => video_uids }).entries
    video_uids.map do |video_uid|
      # replace u per id for Backbone
      if video_tag = video_tags.detect { |v| v.u == video_uid }
        { id: video_uid }.merge(video_tag.meta_data)
      else
        { id: video_uid }
      end
    end
  end

  def self.add_video_stats_data!(videos, video_uids, conditions, options)
    # Research all stats for all videos
    videos_stats = Hash.new { |h,k| h[k] = Hash.new }
    conditions[:u] = { "$in" => video_uids }
    conditions.delete('vl') # remove group limit hack
    top_video_class(options[:period]).where(conditions).only(:u, :d, :vl, :vv).entries.each do |stat|
      videos_stats[stat.u][stat.d.to_i] = { vl: stat.vl, vv: stat.vv }
    end

    step = 1.send(options[:period])
    videos.each do |video|
      if options[:period] == 'seconds'
        video['vl_hash']  = {}
        video['vv_hash']  = {}
      else
        video["vl_array"] = []
        video["vv_array"] = []
      end
      video['vl_sum'] = 0
      video['vv_sum'] = 0

      from_step = options[:from]
      while from_step <= options[:to]
        video_stat = videos_stats[video[:id]][from_step] || {}
        if options[:period] == 'seconds'
          if video_stat.present?
            video['vl_hash'][from_step] = video_stat[:vl].to_i
            video['vv_hash'][from_step] = video_stat[:vv].to_i
          end
        else
          video["vl_array"] << video_stat[:vl].to_i
          video["vv_array"] << video_stat[:vv].to_i
        end
        video['vl_sum'] += video_stat[:vl].to_i
        video['vv_sum'] += video_stat[:vv].to_i
        from_step += step
      end
    end
  end

end
