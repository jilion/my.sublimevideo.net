require 'fast_spec_helper'

require 'stats_migrator'

describe StatsMigrator do
  let(:migrator) { StatsMigrator.new(stat) }
  describe "#migrate" do
    context "with Stat::Site::Day stat" do
      let(:stat) { mock('Stat::Site::Day',
        class: 'Stat::Site::Day',
        d: 'time',
        t: 'site_token',
        pv: 'page_visits',
        st: 'stages',
        s:  'ssl') }

      it "delays to StatsMigratorWorker" do
        StatsMigratorWorker.should_receive(:perform_async).with(
          'Stat::Site::Day',
          site_token: 'site_token',
          time: 'time',
          app_loads: 'page_visits',
          stages: 'stages',
          ssl: 'ssl')
        migrator.migrate
      end
    end

    context "with Stat::Video::Day stat" do
      let(:stat) { mock('Stat::Video::Day',
        class: 'Stat::Video::Day',
        d: 'time',
        st: 'site_token',
        u: 'video_uid',
        vv: 'video_views',
        vl: 'video_loads',
        md: 'player_mode_and_device',
        bp: 'brower_and_platform') }

      it "delays to StatsMigratorWorker" do
        StatsMigratorWorker.should_receive(:perform_async).with(
          'Stat::Video::Day',
          site_token: 'site_token',
          video_uid: 'video_uid',
          time: 'time',
          loads: 'video_loads',
          starts: 'video_views',
          player_mode_and_device: 'player_mode_and_device',
          brower_and_platform: 'brower_and_platform')
        migrator.migrate
      end
    end
  end
end
