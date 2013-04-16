require 'spec_helper'

describe Stat do

  context "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before do
      @log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1313499060-1313499120.gz')
      log_time  = 5.days.ago.change(hour: 0).to_i
      @log      = build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
    end

    describe ".create_stats_from_trackers!", :addons do
      use_vcr_cassette "stat/pusher", erb: true

      context "mixed view event & load event" do
        before do
          site1 = create(:site).tap { |s| s.update_attribute(:token, 'ovjigy83') }
          site2 = create(:site).tap { |s| s.update_attribute(:token, 'site1234') }
          create(:billable_item, site: site1, item: @stats_addon_plan_2)
          described_class.stub(:incs_from_trackers).and_return({
            "ovjigy83"=> {
              inc: { "vv.m" => 1, "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
              set: { "jq" => '1.9.0' },
              add_to_set: { "st" => { :$each => ['s', 'b'] } },
              videos: {
                "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vvc" => 1, "vs.source12" => 1 },
                "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
              }
            },
            "site1234"=> {
              inc: {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
              set: { "s" => true },
              add_to_set: {},
              videos: {
                "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
                "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
              }
            }
          })
        end

        it "create 1 minute site stats for the site with stats addon active" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Minute.count.should eq 1
          Stat::Site::Minute.where(t: 'ovjigy83', d: @log.minute).should be_present
          Stat::Site::Minute.where(t: 'site1234', d: @log.minute).should_not be_present
        end

        it "create 2 minute video stats for the site with stats addon active" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Video::Minute.count.should eq 2
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).first.vlc.should eq 3
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).first.vvc.should eq 1
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).first.vlc.should eq 3
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).first.vvc.should eq 0

          Stat::Video::Minute.where(st: 'site1234', u: 'abcd1234', d: @log.minute).should_not be_present
          Stat::Video::Minute.where(st: 'site1234', u: 'efgh5678', d: @log.minute).should_not be_present
        end

        it "create 1 hour site stats for the site with stats addon active" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Hour.count.should eq 1
          Stat::Site::Hour.where(t: 'ovjigy83', d: @log.hour).should be_present
          Stat::Site::Hour.where(t: 'site1234', d: @log.hour).should_not be_present
        end

        it "create 2 hour video stats for the site with stats addon active" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Video::Hour.count.should eq 2
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).first.vlc.should eq 3
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).first.vvc.should eq 1
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).first.vlc.should eq 3
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).first.vvc.should eq 0

          Stat::Video::Hour.where(st: 'site1234', u: 'abcd1234', d: @log.hour).should_not be_present
          Stat::Video::Hour.where(st: 'site1234', u: 'efgh5678', d: @log.hour).should_not be_present
        end

        it "create 2 day site stats for all sites" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Day.count.should eq 2
          Stat::Site::Day.where(t: 'ovjigy83', d: @log.day).should be_present
          Stat::Site::Day.where(t: 'site1234', d: @log.day).should be_present
        end

        it "adds ssl & stage info" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Day.where(t: 'ovjigy83', d: @log.day).first.s.should be_false
          Stat::Site::Day.where(t: 'ovjigy83', d: @log.day).first.st.should eq ['s', 'b']
          Stat::Site::Day.where(t: 'site1234', d: @log.day).first.s.should be_true
          Stat::Site::Day.where(t: 'site1234', d: @log.day).first.st.should eq []
        end

        it "adds jQuery info" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Day.where(t: 'ovjigy83', d: @log.day).first.jq.should eq '1.9.0'
          Stat::Site::Day.where(t: 'site1234', d: @log.day).first.jq.should be_nil
        end

        it "create 2 day video stats for all sites" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Video::Day.count.should eq 4
          Stat::Video::Day.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).first.vlc.should eq 3
          Stat::Video::Day.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).first.vvc.should eq 1
          Stat::Video::Day.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).first.vlc.should eq 3
          Stat::Video::Day.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).first.vvc.should eq 0

          Stat::Video::Day.where(st: 'site1234', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'site1234', u: 'abcd1234', d: @log.day).first.vlc.should eq 3
          Stat::Video::Day.where(st: 'site1234', u: 'abcd1234', d: @log.day).first.vvc.should eq 0
          Stat::Video::Day.where(st: 'site1234', u: 'efgh5678', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'site1234', u: 'efgh5678', d: @log.day).first.vlc.should eq 3
          Stat::Video::Day.where(st: 'site1234', u: 'efgh5678', d: @log.day).first.vvc.should eq 0
        end

        it "update existing h/d stat" do
          Stat.create_stats_from_trackers!(@log, nil)

          Stat::Site::Minute.count.should eq 1
          Stat::Site::Hour.count.should eq 1
          Stat::Site::Day.count.should eq 2
          log_time = 5.days.ago.change(hour: 0).to_i + 1.minute
          log = build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)

          Stat.create_stats_from_trackers!(log, nil)

          Stat::Site::Minute.count.should eq 2
          Stat::Site::Hour.count.should eq 1
          Stat::Site::Day.count.should eq 2
          Stat::Site::Minute.where(t: 'ovjigy83').lte(d: Time.now).count.should eq 2
          Stat::Site::Minute.where(t: 'ovjigy83', d: log.minute).first.bp.should == { "saf-osx" => 4 }
          Stat::Site::Day.where(t: 'ovjigy83', d: log.day).first.bp.should == { "saf-osx" => 8 }
        end

        it "triggers Pusher on the right private channel for each site" do
          PusherWrapper.should_receive(:trigger).with('stats', 'tick', m: true, h: true, d: true)
          Stat.create_stats_from_trackers!(@log, @trackers)
        end

        it "increments metrics" do
          Librato.should_receive(:increment).with("stats.page_visits", by: 3, source: "main").twice
          Librato.should_receive(:increment).with("stats.page_visits", by: 1, source: "extra")
          Librato.should_receive(:increment).with("stats.video_loads", by: 3, source: "main").exactly(3).times
          Librato.should_receive(:increment).with("stats.video_loads", by: 2, source: "main")
          Librato.should_receive(:increment).with("stats.video_loads", by: 1, source: "extra")
          Librato.should_receive(:increment).with("stats.video_plays", by: 1, source: "main")
          Librato.should_receive(:increment).with("stats.video_plays", by: 1, source: "invalid")
          Librato.should_receive(:increment).with("stats.page_visits.stage_per_min", by: 1, source: "stable").twice
          Librato.should_receive(:increment).with("stats.page_visits.stage_per_min", by: 1, source: "beta")
          Librato.should_receive(:increment).with("stats.page_visits.ssl_per_min", by: 1, source: "ssl")
          Librato.should_receive(:increment).with("stats.page_visits.ssl_per_min", by: 1, source: "non-ssl")
          Librato.should_receive(:increment).with("stats.page_visits.jquery", by: 1, source: "none")
          Librato.should_receive(:increment).with("stats.page_visits.jquery", by: 1, source: "1.9.0")
          Stat.create_stats_from_trackers!(@log, @trackers)
        end
      end

    end

  end

  describe ".incs_from_trackers" do
    let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3" }

    context "load event with 1 video loaded" do
      before do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=h&st=b", user_agent] => 2,
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=f&s=1", user_agent] => 1,
          ["?t=ovjigy83&e=l&d=d&h=e&vu[]=efgh5678&pm[]=f&st=b", user_agent] => 1
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          inc: { "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 2, "md.f.d" => 2 },
          set: { "s" => true },
          add_to_set: { "st" => { :$each => ['b', 's'] } },
          videos: {
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.e" => 1, "vlc" => 1, "bp.saf-osx" => 1, "md.f.d" => 1 }
          }
        }
      })}
    end

    context "load event with 2 videos loaded" do
      before do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 2,
          ["?t=ovjigy83&e=l&d=d&h=m&vu[]=abcd1234&pm[]=f", user_agent] => 1,
          ["?t=ovjigy83&e=l&d=d&h=e&vu[]=efgh5678&pm[]=f", user_agent] => 1,
          ["?t=site1234&e=l&d=m&h=m&vu[]=abcd1234&vu[]=efgh5678&pm[]=h&pm[]=h", user_agent] => 3
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          inc: { "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
          set: {},
          add_to_set: { "st" => { :$each => ['s'] } },
          videos: {
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          inc: { "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          set: {},
          add_to_set: { "st" => { :$each => ['s'] } },
          videos: {
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
          }
        }
      })}
    end

    context "view event" do
      before do
        described_class.stub(:only_stats_trackers).and_return({
          ["?t=ovjigy83&e=s&d=d&h=m&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1,
          ["?t=site1234&e=s&d=d&h=i&vu=abcd1234&vn=My%20Video&vc=source12&vcs[]=source12&vcs[]=source34", user_agent] => 1
        })
      end

      specify { described_class.incs_from_trackers(nil).should eql({
        "ovjigy83"=> {
          inc: { "vv.m" => 1 },
          set: {},
          add_to_set: {},
          videos: {
            "abcd1234" => { "vv.m" => 1, "vs.source12" => 1, "vvc" => 1 }
          }
        },
        "site1234"=> {
          inc: { "vv.i" => 1 },
          set: {},
          add_to_set: {},
          videos: {
            "abcd1234" => { "vv.i" => 1 }
          }
        }
      })}
    end

    context "mixed view event & load event" do
      before do
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
          inc: { "vv.m" => 1, "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
          set: {},
          add_to_set: { "st" => { :$each => ['s'] } },
          videos: {
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vvc" => 1, "vs.source12" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          inc: {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          set: {},
          add_to_set: { "st" => { :$each => ['s'] } },
          videos: {
            "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
          }
        }
      })}
    end

  end

end
