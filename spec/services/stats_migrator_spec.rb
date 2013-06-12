require 'fast_spec_helper'
require 'active_support/core_ext'

require 'stats_migrator'

unless defined? ActiveRecord
  module Stat
    class Site
      class Day; end
    end
    class Video
      class Day; end
    end
  end
end

describe StatsMigrator do
  let(:site) { mock('Site', token: 'site_token') }
  let(:migrator) { StatsMigrator.new(site) }

  describe "#migrate" do
    let(:site_stat) { mock('Stat::Site::Day',
      class: 'Stat::Site::Day',
      d: 'time',
      t: 'site_token',
      pv: 'page_visits',
      st: 'stages',
      s:  'ssl') }
    let(:video_stat) { mock('Stat::Video::Day',
      class: 'Stat::Video::Day',
      d: 'time',
      st: 'site_token',
      u: 'video_uid',
      vv: 'video_views',
      vl: 'video_loads',
      md: 'player_mode_and_device',
      bp: 'browser_and_platform') }
    before {
      Stat::Site::Day.stub_chain(:where, :each).and_yield(site_stat)
      Stat::Video::Day.stub_chain(:where, :each).and_yield(video_stat)
    }

    it "delays site_stat & video_stat to StatsMigratorWorker" do
      StatsMigratorWorker.should_receive(:perform_async).with(
        'Stat::Site::Day',
        site_token: 'site_token',
        time: 'time',
        app_loads: 'page_visits',
        stages: 'stages',
        ssl: 'ssl')
      StatsMigratorWorker.should_receive(:perform_async).with(
        'Stat::Video::Day',
        site_token: 'site_token',
        video_uid: 'video_uid',
        time: 'time',
        loads: 'video_loads',
        starts: 'video_views',
        player_mode_and_device: 'player_mode_and_device',
        browser_and_platform: 'browser_and_platform')
      migrator.migrate
    end
  end
end
