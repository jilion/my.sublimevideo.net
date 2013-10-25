require 'stats_migrator_worker'

class StatsMigrator
  attr_accessor :site

  def initialize(site)
    @site = site
  end

  def migrate(until_day)
    criteria = { d: { :$lte => until_day } }
    Stat::Site::Day.where(criteria.merge(t: site.token)).each { |stat| _migrate_stat(stat) }
    Stat::Video::Day.where(criteria.merge(st: site.token)).each { |stat| _migrate_stat(stat) }
  end

  def self.migrate_all(until_day = Time.utc(2013,10,22))
    Site.select(:id).order(:id).offset(1000).where.not(id: 13589).all.find_in_batches do |site|
      self.delay(queue: 'my-stats_migration').migrate(site.id, until_day)
    end
  end

  def self.migrate(site_id, until_day = nil)
    site = Site.find(site_id)
    StatsMigrator.new(site).migrate(until_day)
  end

  private

  def _migrate_stat(stat)
    StatsMigratorWorker.perform_async(_stat_class(stat), _stat_data(stat))
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
