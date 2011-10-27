require 'spec_helper'

describe Stat do

  context "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      @log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1313499060-1313499120.gz'))
      log_time  = 5.days.ago.change(sec: 0).to_i
      @log      = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
      @trackers = @log.trackers('LogsFileFormat::VoxcastStats')
    end

    describe ".create_stats_from_trackers!" do
      # use_vcr_cassette "stat/pusher", erb: true

      it "create three stats m/h/d for each token" do
        Stat.create_stats_from_trackers!(@log, @trackers)
        Stat.count.should eql(3)
        Stat.where(t: 'ovjigy83', m: @log.minute).should be_present
        Stat.where(t: 'ovjigy83', h: @log.hour).should be_present
        Stat.where(t: 'ovjigy83', d: @log.day).should be_present
      end

      it "update existing h/d stats" do
        Stat.create_stats_from_trackers!(@log, @trackers)
        log = Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1310993700-1310993760.gz', file: @log_file)
        Stat.create_stats_from_trackers!(log, @trackers)
        Stat.count.should eql(6)
        Stat.where(t: 'ovjigy83').m_before(Time.now).count.should eql(2)
        Stat.where(t: 'ovjigy83', d: log.day).first.bp.should eql({ "saf-osx" => 1, "chr-osx" => 1, "fir-osx" => 1 })
      end

      # it "triggers Pusher on the right private channel for each site" do
      #   mock_channel = mock('channel')
      #   mock_channel.should_receive(:trigger).once.with('tick', {})
      #   Pusher.stub(:[]).with("stats") { mock_channel }
      #   Stat.create_stats_from_trackers!(@log, @trackers)
      # end
    end

    describe ".incs_from_trackers" do
      it "returns incs for each token" do
        Stat.incs_from_trackers(@trackers).should eql({
          "ovjigy83" => { "pv.m" => 3, "bp.saf-osx" => 1, "bp.chr-osx" => 1, "bp.fir-osx" => 1 }
        })
      end
    end

    describe ".delay_clear_old_seconds_minutes_and_hours_stats" do
      it "delays clear_old_seconds_minutes_and_hours_stats if not already delayed" do
        expect { Stat.delay_clear_old_seconds_minutes_and_hours_stats }.to change(Delayed::Job, :count).by(1)
        Delayed::Job.last.run_at.should be_within(60).of(1.minutes.from_now)
      end

      it "delays nothing if already delayed" do
        Stat.delay_clear_old_seconds_minutes_and_hours_stats
        expect { Stat.delay_clear_old_seconds_minutes_and_hours_stats }.to change(Delayed::Job, :count).by(0)
      end
    end

    describe ".clear_old_seconds_minutes_and_hours_stats" do
      use_vcr_cassette "site_stat/pusher", erb: true

      it "delete old minutes and days site stats, but keep all stats" do
        Stat.create_stats_from_trackers!(@log, @trackers)
        log = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{1.minute.ago.change(sec: 0).to_i}-#{Time.now.utc.change(sec: 0).to_i}.gz", file: @log_file)
        Stat.create_stats_from_trackers!(log, @trackers)
        Stat.count.should eql(6)
        Stat.m_before(180.minutes.ago).count.should eql(1)
        Stat.h_before(72.hours.ago).count.should eql(1)
        Stat.clear_old_seconds_minutes_and_hours_stats
        Stat.count.should eql(4)
        Stat.m_before(180.minutes.ago).count.should eql(0)
        Stat.h_before(72.hours.ago).count.should eql(0)
      end

      it "delays itself" do
        expect { Stat.clear_old_seconds_minutes_and_hours_stats }.to change(Delayed::Job, :count).by(1)
        Delayed::Job.last.run_at.should be_within(60).of(1.minutes.from_now)
      end
    end

  end

end
