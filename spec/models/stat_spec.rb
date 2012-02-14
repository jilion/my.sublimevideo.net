require 'spec_helper'

describe Stat do

  context "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      @log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1313499060-1313499120.gz'))
      log_time  = 5.days.ago.change(hour: 0).to_i
      @log      = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
    end

    describe ".create_stats_from_trackers!"  do
      use_vcr_cassette "stat/pusher", erb: true

      context "mixed view event & load event" do
        before(:each) do
          described_class.stub(:incs_from_trackers).and_return({
            "ovjigy83"=> {
              :inc => { "vv.m" => 1, "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
              :videos   => {
                "abcd1234" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vs.source12" => 1 },
                "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
              }
            },
            "site1234"=> {
              :inc => {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
              :videos   => {
                "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
                "efgh5678" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
              }
            }
          })
        end

        it "create three stats m/h/d for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site.count.should eql(6)
          Stat::Video.count.should eql(12)
          Stat::Site.where(t: 'ovjigy83', m: @log.minute).should be_present
          Stat::Site.where(t: 'ovjigy83', h: @log.hour).should be_present
          Stat::Site.where(t: 'ovjigy83', d: @log.day).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'abcd1234', m: @log.minute).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'abcd1234', h: @log.hour).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'efgh5678', m: @log.minute).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'efgh5678', h: @log.hour).should be_present
          Stat::Video.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).should be_present
          Stat::Site.where(t: 'site1234', m: @log.minute).should be_present
          Stat::Site.where(t: 'site1234', h: @log.hour).should be_present
          Stat::Site.where(t: 'site1234', d: @log.day).should be_present
          Stat::Video.where(st: 'site1234', u: 'abcd1234', m: @log.minute).should be_present
          Stat::Video.where(st: 'site1234', u: 'abcd1234', h: @log.hour).should be_present
          Stat::Video.where(st: 'site1234', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video.where(st: 'site1234', u: 'efgh5678', m: @log.minute).should be_present
          Stat::Video.where(st: 'site1234', u: 'efgh5678', h: @log.hour).should be_present
          Stat::Video.where(st: 'site1234', u: 'efgh5678', d: @log.day).should be_present
        end

        it "update existing h/d stats" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site.count.should eql(6)
          log_time = 5.days.ago.change(hour: 0).to_i + 1.minute
          log  = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
          Stat.create_stats_from_trackers!(log, nil)
          Stat::Site.count.should eql(8)
          Stat::Site.where(t: 'ovjigy83').m_before(Time.now).count.should eql(2)
          Stat::Site.where(t: 'ovjigy83', m: log.minute).first.bp.should eql({ "saf-osx" => 4 })
          Stat::Site.where(t: 'ovjigy83', d: log.day).first.bp.should eql({ "saf-osx" => 8 })
        end

        it "triggers Pusher on the right private channel for each site" do
          mock_channel = mock('channel')
          mock_channel.should_receive(:trigger).once.with('tick', m: true, h: true, d: true)
          Pusher.stub(:[]).with("stats") { mock_channel }
          Stat.create_stats_from_trackers!(@log, @trackers)
        end
      end

    end

  end

  describe ".incs_from_trackers" do
    let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3" }

    context "load event with 1 video loaded" do
      before(:each) do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=h", user_agent] => 2,
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=f", user_agent] => 1,
          ["?t=ovjigy83&e=l&d=d&h=e&vu[]=efgh5678&pm[]=f", user_agent] => 1
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          :inc => { "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 2, "md.f.d" => 2 },
          :videos   => {
            "abcd1234" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.e" => 1, "bp.saf-osx" => 1, "md.f.d" => 1 }
          }
        }
      })}
    end

    context "load event with 2 videos loaded" do
      before(:each) do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 2,
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=f", user_agent] => 1,
          ["?t=ovjigy83&e=l&d=d&h=e&vu[]=efgh5678&pm[]=f", user_agent] => 1,
          ["?t=site1234&e=l&d=m&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 3
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          :inc => { "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
          :videos   => {
            "abcd1234" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          :inc => { "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          :videos   => {
            "abcd1234" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
          }
        }
      })}
    end

    context "view event" do
      before(:each) do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=s&d=d&h=m&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1,
          ["?t=site1234&e=s&d=d&h=i&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          :inc => { "vv.m" => 1 },
          :videos   => {
            "abcd1234" => { "vv.m" => 1, "vs.source12" => 1 }
          }
        },
        "site1234"=> {
          :inc => { "vv.i" => 1 },
          :videos   => {
            "abcd1234" => { "vv.i" => 1 }
          }
        }
      })}
    end

    context "mixed view event & load event" do
      before(:each) do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 2,
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=f", user_agent] => 1,
          ["?t=ovjigy83&e=l&d=d&h=e&vu[]=efgh5678&pm[]=f", user_agent] => 1,
          ["?t=site1234&e=l&d=m&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 3,
          ["?t=ovjigy83&e=s&d=d&h=m&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1,
          ["?t=site1234&e=s&d=d&h=i&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          :inc => { "vv.m" => 1, "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
          :videos   => {
            "abcd1234" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vs.source12" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          :inc => {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          :videos   => {
            "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
          }
        }
      })}
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

    it "delete old seconds, minutes and hours site stats, but keep all days site stats" do
      Timecop.freeze(Time.now) do
        Factory.create(:site_stat, d: nil, h: nil, m: nil, s: 62.seconds.ago)
        Factory.create(:site_stat, d: nil, h: nil, m: nil, s: 63.seconds.ago)
        Factory.create(:site_stat, d: nil, h: nil, m: 62.minutes.ago.change(s: 0), s: nil)
        Factory.create(:site_stat, d: nil, h: nil, m: 61.minutes.ago.change(s: 0), s: nil)
        Factory.create(:site_stat, d: nil, h: 26.hours.ago.change(m: 0), m: nil, s: nil)
        Factory.create(:site_stat, d: nil, h: 25.hours.ago.change(m: 0), m: nil, s: nil)
        Factory.create(:site_stat, d: 99.days.ago.change(h: 0), h: nil, m: nil, s: nil)
        Factory.create(:site_stat, d: 30.days.ago.change(h: 0), h: nil, m: nil, s: nil)

        Stat::Site.count.should eql(8)
        Stat::Site.s_before(60.seconds.ago).count.should eql(2)
        Stat::Site.m_before(60.minutes.ago).count.should eql(2)
        Stat::Site.h_before(20.hours.ago).count.should eql(2)
        Stat::Site.d_before(10.days.ago).count.should eql(2)
        Stat.clear_old_seconds_minutes_and_hours_stats
        Stat::Site.count.should eql(5)
        Stat::Site.s_before(60.seconds.ago).count.should eql(1)
        Stat::Site.m_before(60.minutes.ago).count.should eql(1)
        Stat::Site.h_before(20.hours.ago).count.should eql(1)
        Stat::Site.d_before(10.days.ago).count.should eql(2)
      end
    end

    it "delete old seconds, minutes and hours video stats, but keep all days video stats" do
      Timecop.freeze(Time.now) do
        Factory.create(:video_stat, s: 62.seconds.ago)
        Factory.create(:video_stat, s: 63.seconds.ago)
        Factory.create(:video_stat, m: 62.minutes.ago.change(s: 0))
        Factory.create(:video_stat, m: 61.minutes.ago.change(s: 0))
        Factory.create(:video_stat, h: 26.hours.ago.change(m: 0))
        Factory.create(:video_stat, h: 25.hours.ago.change(m: 0))
        Factory.create(:video_stat, d: 99.days.ago.change(h: 0))
        Factory.create(:video_stat, d: 30.days.ago.change(h: 0))

        Stat::Video.count.should eql(8)
        Stat::Video.s_before(60.seconds.ago).count.should eql(2)
        Stat::Video.m_before(60.minutes.ago).count.should eql(2)
        Stat::Video.h_before(20.hours.ago).count.should eql(2)
        Stat::Video.d_before(10.days.ago).count.should eql(2)
        Stat.clear_old_seconds_minutes_and_hours_stats
        Stat::Video.count.should eql(5)
        Stat::Video.s_before(60.seconds.ago).count.should eql(1)
        Stat::Video.m_before(60.minutes.ago).count.should eql(1)
        Stat::Video.h_before(20.hours.ago).count.should eql(1)
        Stat::Video.d_before(10.days.ago).count.should eql(2)
      end
    end

    it "delays itself" do
      expect { Stat.clear_old_seconds_minutes_and_hours_stats }.to change(Delayed::Job, :count).by(1)
      Delayed::Job.last.run_at.should be_within(60).of(1.minutes.from_now)
    end
  end

end
