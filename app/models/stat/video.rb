# encoding: utf-8

module Stat::Video
  extend ActiveSupport::Concern
  include Stat

  included do
    field :st, type: String # Site token
    field :u,  type: String # Video uid

    field :vl, type: Hash, default: {} # Video Loads: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
    field :vs, type: Hash, default: {} # Video Sources View { '5062d010' (video source crc32) => 32, ... }

    # top_video specific query field
    field :vlc, type: Integer, default: 0 # Video Loads Chart (main + extra)
    field :vvc, type: Integer, default: 0 # Video Views Chart (main + extra)

    index st: 1, u: 1, d: 1
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
  # @return [Hash] with an array of video hash with video tag meta_data and period 'vl' & 'vv' totals + vv period array, the total amount of videos viewed or loaded during the period and the start_time of the period
  #
  def self.top_videos(site_token, options = {})
    options[:from], options[:to] = options[:from].to_i, options[:to].to_i
    options    = options.symbolize_keys.reverse_merge(period: 'days', sort_by: 'vv', limit: 5)
    conditions = { st: site_token, d: { :$gte => Time.at(options[:from]), :$lte => Time.at(options[:to]) } }
    video_uids, total = top_video_uids(conditions, options)
    videos            = videos_with_tags_meta_data(site_token, video_uids)
    add_video_stats_data!(videos, video_uids, conditions, options)
    # Resort with real sum data
    videos.sort_by! { |video| video["#{options[:sort_by]}_sum"] }.reverse!

    { videos: videos, total: total }.merge(options.slice(:period, :from, :to, :sort_by, :limit))
  end

private

  def self.video_class(period)
    case period
    when 'seconds' then Stat::Video::Second
    when 'minutes' then Stat::Video::Minute
    when 'hours'   then Stat::Video::Hour
    when 'days'    then Stat::Video::Day
    end
  end

  def self.top_video_uids(conditions, options)
    # Demo Page
    if conditions[:st] == SiteToken[:www]
      conditions[:u]  = { :$in => %w[home features-lightbox features-playlist-1 features-playlist-2 features-playlist-3 features-playlist-4 demo-single demo-lightbox-1 demo-lightbox-2 demo-lightbox-3 demo-lightbox-4 demo-playlist-1 demo-playlist-2 demo-playlist-3 demo-playlist-4] }
    end

    # Reduce number of stats to group if too many.
    if %w[hours days].include?(options[:period])
      stats_count = video_class(options[:period]).where(conditions).count

      if stats_count >= 20_000
        conditions['vlc'] = { :$gte => 10 + stats_count / 20_000 }
      end
    end

    videos = video_class(options[:period]).collection.aggregate([
      { :$match => conditions },
      { :$project => {
          _id: 0,
          u: 1,
          options[:sort_by] => 1 } },
      { :$group => {
          _id: '$u',
          "#{options[:sort_by]}Sum" => { :$sum => "$#{options[:sort_by]}" } } },
      { :$project => {
          _id: 0,
          u: '$_id',
          "#{options[:sort_by]}Sum" => 1 } },
      { :$sort => { "#{options[:sort_by]}Sum" => -1 } }
    ])

    total = videos.size

    # Seconds top videos stats will be update real-time so we need more that the limit
    limit  = options[:period] == 'seconds' ? 40 : options[:limit].to_i
    videos = videos.take(limit)

    [videos.map { |v| v["u"] }, total]
  end

  def self.videos_with_tags_meta_data(site_token, video_uids)
    video_tags = VideoTag.where(st: site_token, u: { :$in => video_uids }).entries
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
    conditions[:u] = { :$in => video_uids }
    conditions.delete('vlc') # remove group limit hack
    video_class(options[:period]).where(conditions).only(:u, :d, :vlc, :vvc).entries.each do |stat|
      videos_stats[stat.u][stat.d.to_i] = { vlc: stat.vlc, vvc: stat.vvc }
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
            video['vl_hash'][from_step] = video_stat[:vlc].to_i
            video['vv_hash'][from_step] = video_stat[:vvc].to_i
          end
        else
          video["vl_array"] << video_stat[:vlc].to_i
          video["vv_array"] << video_stat[:vvc].to_i
        end
        video['vl_sum'] += video_stat[:vlc].to_i
        video['vv_sum'] += video_stat[:vvc].to_i
        from_step += step
      end
    end
  end

end
