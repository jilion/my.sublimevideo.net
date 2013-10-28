require 'stats_migrator_worker'

class StatsMigrator
  attr_accessor :site

  def initialize(site)
    @site = site

    @last_queue_check = Time.now.utc
    @queue_size = 0
  end

  def self.check_migration
    _all_sites do |site|
      migrator = StatsMigrator.new(site)
      old_totals = migrator.totals
      new_totals = SiteAdminStat.migration_totals(site.token)
      if old_totals == new_totals
        print '.'
      else
        puts "/nMigration failed: #{site.token} (#{site.id}): old #{old_totals} / new #{new_totals}"
      end
    end
    puts "/nCheck done"
  end

  def self.migrate_all
    _all_sites do |site|
      self.delay(queue: 'my-stats_migration').migrate(site.id)
    end
  end

  def self.migrate(site_id)
    site = Site.find(site_id)
    StatsMigrator.new(site).migrate
  end

  def migrate
    _all_stats { |stat| _migrate_stat(stat) }
  end

  def totals
    @totals = { app_loads: 0, loads: 0, starts: 0 }
    Stat::Site::Day.where(_date_criteria.merge(t: site.token)).only(:pv).each_by(10_000) do |stat|
      @totals[:app_loads] += stat.pv.slice(*%w[m e s d i]).values.sum
    end
    Stat::Video::Day.where(_date_criteria.merge(st: site.token)).only(:vl, :vv).each_by(10_000) do |stat|
      @totals[:loads] += (stat.vl['m'].to_i + stat.vl['e'].to_i + stat.vl['em'].to_i)
      @totals[:starts] += (stat.vv['m'].to_i + stat.vv['e'].to_i + stat.vv['em'].to_i)
    end
    @totals
  end

  private

  def _all_sites(&block)
    Site.select(:id, :token).find_in_batches do |sites|
      sites.each { |site| yield site }
    end
  end

  def _all_stats(&block)
    Stat::Site::Day.where(_date_criteria.merge(t: site.token)).each_by(1000) { |stat| yield stat }
    Stat::Video::Day.where(_date_criteria.merge(st: site.token)).each_by(1000) { |stat| yield stat }
  end

  def _date_criteria
    { d: { :$lte => Time.utc(2013,10,22) } }
  end

  def _migrate_stat(stat)
    sleep 1 if _queue_size >= 10_000
    StatsMigratorWorker.perform_async(_stat_class(stat), _stat_data(stat))
  end

  def _queue_size
    if @last_queue_check < 1.second.ago
      @queue_size = Sidekiq::Queue.new('stats-migration').size
      @last_queue_check = Time.now.utc
    end
    @queue_size
  end

  def _stat_class(stat)
    stat.class.to_s
  end

  def _stat_data(stat)
    case _stat_class(stat)
    when 'Stat::Site::Day'
      { site_token: stat.t,
        time: stat.d,
        app_loads: stat.pv,
        stages: stat.st,
        ssl: stat.s,
        sa: _subscribed_to_realtime_stat_addon? }
    when 'Stat::Video::Day'
      { site_token: stat.st,
        video_uid: stat.u,
        time: stat.d,
        loads: stat.vl,
        starts: stat.vv,
        player_mode_and_device: stat.md,
        browser_and_platform: stat.bp,
        sa: _subscribed_to_realtime_stat_addon? }
    end
  end

  def _subscribed_to_realtime_stat_addon?
    @_subscribed ||= site.subscribed_to?(AddonPlan.get('stats', 'realtime')).present?
  end

end
