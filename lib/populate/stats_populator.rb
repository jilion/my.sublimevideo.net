class StatsPopulator < Populator

  def execute(site)
    SiteUsage.where(site_id: site.id).delete_all
    Stat::Site::Day.where(t: site.token).delete_all
    Stat::Site::Hour.where(t: site.token).delete_all
    Stat::Site::Minute.where(t: site.token).delete_all
    Stat::Site::Second.where(t: site.token).delete_all
    Stat::Video::Day.where(st: site.token).delete_all
    Stat::Video::Hour.where(st: site.token).delete_all
    Stat::Video::Minute.where(st: site.token).delete_all
    Stat::Video::Second.where(st: site.token).delete_all

    generate_stats(site, 95, 'day')
    generate_stats(site, 25, 'hour')
    generate_stats(site, 60, 'minute')
    generate_stats(site, 60, 'second')

    SiteCountersUpdater.new(site).update_last_30_days_video_views_counters
    puts "Fake stats created for #{site.hostname}"
  end

  def generate_stats(site, count, scale = 'day')
    puts "Generating #{count} #{scale}s of stats for #{site.hostname}"
    duration = 1.send(scale)

    count.times.each do |i|
      time = i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time
      create_site_usage(site, time) if scale == 'day'

      Stat::Site.const_get(scale.classify).collection.find(t: site.token, d: time).update({ :$inc => random_site_stats_inc(duration) }, upsert: true)

      site.video_tags.pluck(:uid).each do |video_uid|
        Stat::Video.const_get(scale.classify).collection.find(st: site.token, u: video_uid, d: time).update({ :$inc => random_video_stats_inc(duration) }, upsert: true)
      end
    end
  end

  def create_site_usage(site, day)
    base_video_views_count     = rand_video_views_count
    loader_hits                = base_video_views_count * rand(100)
    main_player_hits           = (base_video_views_count * rand).to_i
    main_player_hits_cached    = (base_video_views_count * rand).to_i
    extra_player_hits          = (base_video_views_count * rand).to_i
    extra_player_hits_cached   = (base_video_views_count * rand).to_i
    dev_player_hits            = rand(100)
    dev_player_hits_cached     = (dev_player_hits * rand).to_i
    invalid_player_hits        = rand(500)
    invalid_player_hits_cached = (invalid_player_hits * rand).to_i
    player_hits = main_player_hits + main_player_hits_cached + extra_player_hits + extra_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
    requests_s3 = player_hits - (main_player_hits_cached + extra_player_hits_cached + dev_player_hits_cached + invalid_player_hits_cached)

    SiteUsage.create!(
      day: day.utc.midnight,
      site_id: site.id,
      loader_hits: loader_hits,
      main_player_hits: main_player_hits,
      main_player_hits_cached: main_player_hits_cached,
      extra_player_hits: extra_player_hits,
      extra_player_hits_cached: extra_player_hits_cached,
      dev_player_hits: dev_player_hits,
      dev_player_hits_cached: dev_player_hits_cached,
      invalid_player_hits: invalid_player_hits,
      invalid_player_hits_cached: invalid_player_hits_cached,
      player_hits: player_hits,
      flash_hits: (player_hits * rand / 3).to_i,
      requests_s3: requests_s3,
      traffic_s3: requests_s3 * 150000, # 150 KB
      traffic_voxcast: player_hits * 150000
    )
  end

  private

  def rand_video_views_count(plan_video_views = rand(1_000_000))
    case rand(4)
    when 0
      plan_video_views/30.0 - (plan_video_views/30.0/4)
    when 1
      plan_video_views/30.0 - (plan_video_views/30.0/8)
    when 2
      plan_video_views/30.0 + (plan_video_views/30.0/4)
    when 3
      plan_video_views/30.0 + (plan_video_views/30.0/8)
    end.to_i
  end

  def random_site_stats_inc(i, force = nil)
    {
      # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
      "pv.m"  => force || (i * rand).round,
      "pv.e"  => force || (i * rand / 2).round,
      "pv.em" => force || (i * rand / 2).round,
      "pv.d"  => force || (i * rand / 2).round,
      "pv.i"  => force || (i * rand / 2).round,
      # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
      "vv.m"  => force || (i * rand / 2).round,
      "vv.e"  => force || (i * rand / 4).round,
      "vv.em" => force || (i * rand / 4).round,
      "vv.d"  => force || (i * rand / 6).round,
      "vv.i"  => force || (i * rand / 6).round,
      # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
      "md.h.d" => i * rand(12),
      "md.h.m" => i * rand(5),
      "md.h.t" => i * rand(3),
      "md.f.d" => i * rand(6),
      "md.f.m" => 0, #i * rand(2),
      "md.f.t" => 0, #i * rand(2),
      # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
      "bp.iex-win" => i * rand(35), # 35% in total
      "bp.fir-win" => i * rand(18), # 26% in total
      "bp.fir-osx" => i * rand(8),
      "bp.chr-win" => i * rand(11), # 21% in total
      "bp.chr-osx" => i * rand(10),
      "bp.saf-win" => i * rand(1).round, # 6% in total
      "bp.saf-osx" => i * rand(5),
      "bp.saf-ipo" => i * rand(1),
      "bp.saf-iph" => i * rand(2),
      "bp.saf-ipa" => i * rand(2),
      "bp.and-and" => i * rand(6)
    }
  end

  def random_video_stats_inc(i, force = nil)
    {
      # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
      "vl.m"  => force || (i * rand(20)).round,
      "vl.e"  => force || (i * rand(4)).round,
      "vl.em" => force || (i * rand(2)).round,
      "vl.d"  => force || (i * rand(2)).round,
      "vl.i"  => force || (i * rand(2)).round,
      "vlc"  => force || (i * rand(30)).round,
      # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
      "vv.m"  => force || (i * rand(10)).round,
      "vv.e"  => force || (i * rand(3)).round,
      "vv.em" => force || (i * rand(3)).round,
      "vv.d"  => force || (i * rand(2)).round,
      "vv.i"  => force || (i * rand(2)).round,
      "vvc"  => force || (i * rand(20)).round,
      # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
      "md.h.d" => i * rand(12),
      "md.h.m" => i * rand(5),
      "md.h.t" => i * rand(3),
      "md.f.d" => i * rand(6),
      "md.f.m" => 0, #i * rand(2),
      "md.f.t" => 0, #i * rand(2),
      # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
      "bp.iex-win" => i * rand(35), # 35% in total
      "bp.fir-win" => i * rand(18), # 26% in total
      "bp.fir-osx" => i * rand(8),
      "bp.chr-win" => i * rand(11), # 21% in total
      "bp.chr-osx" => i * rand(10),
      "bp.saf-win" => i * rand(1).round, # 6% in total
      "bp.saf-osx" => i * rand(5),
      "bp.saf-ipo" => i * rand(1),
      "bp.saf-iph" => i * rand(2),
      "bp.saf-ipa" => i * rand(2),
      "bp.and-and" => i * rand(6)
    }
  end

end
