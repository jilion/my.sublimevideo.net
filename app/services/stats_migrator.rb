require 'stats_migrator_worker'

class StatsMigrator
  MIGRATION_DATE = Time.utc(2013,10,31)

  attr_accessor :site

  def initialize(site)
    @site = site
  end

  def self.failed_migrations
    Site.select(:id, :token).where('created_at <= ?', MIGRATION_DATE).where(stats_migration_success: false).count
  end

  def self.check_all_migration
    _all_sites { |site| self.delay(queue: 'my-stats_migration').check_migration(site.id) }
  end

  def self.migrate_all
    _all_sites { |site| self.delay(queue: 'my-stats_migration').migrate(site.id) }
  end

  def self.migrate(site_id)
    return if site_id > 58449
    if site = Site.find_by_id(site_id)
      Stat::Site::Day.where(d: { :$lte => MIGRATION_DATE }, t: site.token).pluck(:d).each do |day|
        self.delay(queue: 'my-stats_migration').migrate_day(site.id, day)
      end
    end
    self.delay(queue: 'my-stats_migration').migrate(site_id + 1)
  end

  def self.migrate_day(site_id, day)
    site = Site.find(site_id)
    StatsMigrator.new(site).migrate(day)
  end

  def migrate(day)
    @data = { app_loads: {}, stages: [], ssl: false }
    _all_site_stats(day) { |stat| @data = _merge_site_data(stat, @data) }
    _migrate_stat('site', @data, day)
    @data = { loads: {}, starts: {} }
    _all_video_stats(day) { |stat| @data = _merge_video_data(stat, @data) }
    _migrate_stat('video', @data, day)
  end

  def self.check_migration(site_id)
    site = Site.find(site_id)
    StatsMigrator.new(site).check_migration
  end

  def check_migration
    if totals == SiteAdminStat.migration_totals(site.token)
      site.update_column(:stats_migration_success, true)
    end
  end

  def totals
    @totals = { app_loads: 0, loads: 0, starts: 0 }
    Stat::Site::Day.where(_date_criteria.merge(t: site.token)).only(:pv).each_by(10_000) do |stat|
      @totals[:app_loads] += stat.pv.values.sum
    end
    Stat::Video::Day.where(_date_criteria.merge(st: site.token)).only(:vl, :vv).each_by(10_000) do |stat|
      @totals[:loads] += stat.vl.values.sum
      @totals[:starts] += stat.vv.values.sum
    end
    @totals
  end

  private

  def self._all_sites(&block)
    Site.select(:id, :token).where('created_at <= ?', MIGRATION_DATE).where(stats_migration_success: false).find_in_batches do |sites|
      sites.each { |site| yield site }
    end
  end

  def _all_site_stats(day, &block)
    Stat::Site::Day.where(d: day, t: site.token).each_by(1000) { |stat| yield stat }
  end

  def _all_video_stats(day, &block)
    Stat::Video::Day.where(d: day, st: site.token).each_by(1000) { |stat| yield stat }
  end

  def _date_criteria
    { d: { :$lte => MIGRATION_DATE } }
  end

  def _migrate_stat(type, data, day)
    sleep 1 while Sidekiq::Queue.new('stats-migration').size >= 10_000
    StatsMigratorWorker.perform_async(type, data.merge(site_token: site.token, time: day))
  rescue => ex
    Honeybadger.notify_or_ignore(ex, context: { data: data, day: day, type: type })
  end

  def _merge_site_data(stat, data)
    data[:app_loads] = stat.pv.merge(data[:app_loads]) { |k, old_v, new_v| old_v + new_v }
    data[:stages].push(stat.st) unless data[:stages].include?(stat.st)
    data[:ssl] = true if stat.s
    data
  end

  def _merge_video_data(stat, data)
    data[:loads] = stat.vl.merge(data[:loads]) { |k, old_v, new_v| old_v + new_v }
    data[:starts] = stat.vv.merge(data[:starts]) { |k, old_v, new_v| old_v + new_v }
    data
  end

  # def _stat_class(stat)
  #   stat.class.to_s
  # end

  # def _stat_data(stat)
  #   case _stat_class(stat)
  #   when 'Stat::Site::Day'
  #     { site_token: stat.t,
  #       time: stat.d,
  #       app_loads: stat.pv,
  #       stages: stat.st,
  #       ssl: stat.s,
  #       sa: _subscribed_to_realtime_stat_addon? }
  #   when 'Stat::Video::Day'
  #     { site_token: stat.st,
  #       video_uid: stat.u,
  #       time: stat.d,
  #       loads: stat.vl,
  #       starts: stat.vv,
  #       player_mode_and_device: stat.md,
  #       browser_and_platform: stat.bp,
  #       sa: _subscribed_to_realtime_stat_addon? }
  #   end
  # end

  # def _subscribed_to_realtime_stat_addon?
  #   @_subscribed ||= site.subscribed_to?(AddonPlan.get('stats', 'realtime')).present?
  # end

end
