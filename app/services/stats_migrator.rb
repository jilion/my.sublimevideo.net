require 'stats_migrator_worker'

class StatsMigrator

  attr_accessor :stat

  def initialize(stat)
    @stat = stat
  end

  def migrate
    StatsMigratorWorker.perform_async(_stat_class, _stat_data)
  end

  def self.migrate_site(token)
    Stat::Site::Day.where(t: token).each { |stat| new(stat).migrate }
    Stat::Video::Day.where(st: token).each { |stat| new(stat).migrate }
  end

  private

  def _stat_class
    stat.class.to_s
  end

  def _stat_data
    case _stat_class
    when 'Stat::Site::Day'
      { site_token: stat.t,
        time: stat.d,
        app_loads: stat.pv,
        stages: stat.st,
        ssl: stat.s }
    when 'Stat::Video::Day'
      { site_token: stat.st,
        video_uid: stat.u,
        time: stat.d,
        loads: stat.vl,
        starts: stat.vv,
        player_mode_and_device: stat.md,
        brower_and_platform: stat.bp }
    end
  end
end
