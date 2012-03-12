require 'spec_helper'

describe Stat do

  context "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      @log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1313499060-1313499120.gz'))
      log_time  = 5.days.ago.change(hour: 0).to_i
      @log      = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
    end

    describe ".create_stats_from_trackers!" do
      use_vcr_cassette "stat/pusher", erb: true

      context "mixed view event & load event" do
        before(:each) do
          site = Factory.create(:site)
          site.update_attribute(:token, 'ovjigy83')
          site = Factory.create(:site)
          site.update_attribute(:token, 'site1234')
          described_class.stub(:incs_from_trackers).and_return({
            "ovjigy83"=> {
              :inc => { "vv.m" => 1, "pv.m" => 3, "pv.e" => 1, "bp.saf-osx" => 4, "md.h.d" => 4, "md.f.d" => 2 },
              :videos   => {
                "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vvc" => 1, "vs.source12" => 1 },
                "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
              }
            },
            "site1234"=> {
              :inc => {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
              :videos   => {
                "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
                "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
              }
            }
          })
        end

        it "create three minute site stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site::Minute.count.should eql(2)
          Stat::Site::Minute.where(t: 'ovjigy83', d: @log.minute).should be_present
          Stat::Site::Minute.where(t: 'site1234', d: @log.minute).should be_present
        end
        it "create three minute video stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Video::Minute.count.should eql(4)
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).first.vlc.should eq(3)
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'abcd1234', d: @log.minute).first.vvc.should eq(1)
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).first.vlc.should eq(3)
          Stat::Video::Minute.where(st: 'ovjigy83', u: 'efgh5678', d: @log.minute).first.vvc.should eq(0)
          Stat::Video::Minute.where(st: 'site1234', u: 'abcd1234', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'site1234', u: 'abcd1234', d: @log.minute).first.vlc.should eq(3)
          Stat::Video::Minute.where(st: 'site1234', u: 'abcd1234', d: @log.minute).first.vvc.should eq(0)
          Stat::Video::Minute.where(st: 'site1234', u: 'efgh5678', d: @log.minute).should be_present
          Stat::Video::Minute.where(st: 'site1234', u: 'efgh5678', d: @log.minute).first.vlc.should eq(3)
          Stat::Video::Minute.where(st: 'site1234', u: 'efgh5678', d: @log.minute).first.vvc.should eq(0)
        end
        it "create three hour site stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site::Hour.count.should eql(2)
          Stat::Site::Hour.where(t: 'ovjigy83', d: @log.hour).should be_present
          Stat::Site::Hour.where(t: 'site1234', d: @log.hour).should be_present
        end
        it "create three hour video stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Video::Hour.count.should eql(4)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).first.vlc.should eq(3)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.hour).first.vvc.should eq(1)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).first.vlc.should eq(3)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.hour).first.vvc.should eq(0)
          Stat::Video::Hour.where(st: 'site1234', u: 'abcd1234', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'site1234', u: 'abcd1234', d: @log.hour).first.vlc.should eq(3)
          Stat::Video::Hour.where(st: 'site1234', u: 'abcd1234', d: @log.hour).first.vvc.should eq(0)
          Stat::Video::Hour.where(st: 'site1234', u: 'efgh5678', d: @log.hour).should be_present
          Stat::Video::Hour.where(st: 'site1234', u: 'efgh5678', d: @log.hour).first.vlc.should eq(3)
          Stat::Video::Hour.where(st: 'site1234', u: 'efgh5678', d: @log.hour).first.vvc.should eq(0)
        end
        it "create three day site stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site::Day.count.should eql(2)
          Stat::Site::Day.where(t: 'ovjigy83', d: @log.day).should be_present
          Stat::Site::Hour.where(t: 'site1234', d: @log.day).should be_present
        end
        it "create three day video stats for each token" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Video::Day.count.should eql(4)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).first.vlc.should eq(3)
          Stat::Video::Day.where(st: 'ovjigy83', u: 'abcd1234', d: @log.day).first.vvc.should eq(1)
          Stat::Video::Hour.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).first.vlc.should eq(3)
          Stat::Video::Day.where(st: 'ovjigy83', u: 'efgh5678', d: @log.day).first.vvc.should eq(0)
          Stat::Video::Hour.where(st: 'site1234', u: 'abcd1234', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'site1234', u: 'abcd1234', d: @log.day).first.vlc.should eq(3)
          Stat::Video::Day.where(st: 'site1234', u: 'abcd1234', d: @log.day).first.vvc.should eq(0)
          Stat::Video::Hour.where(st: 'site1234', u: 'efgh5678', d: @log.day).should be_present
          Stat::Video::Day.where(st: 'site1234', u: 'efgh5678', d: @log.day).first.vlc.should eq(3)
          Stat::Video::Day.where(st: 'site1234', u: 'efgh5678', d: @log.day).first.vvc.should eq(0)
        end

        it "update existing h/d stat" do
          Stat.create_stats_from_trackers!(@log, nil)
          Stat::Site::Minute.count.should eql(2)
          Stat::Site::Hour.count.should eql(2)
          Stat::Site::Day.count.should eql(2)
          log_time = 5.days.ago.change(hour: 0).to_i + 1.minute
          log  = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
          Stat.create_stats_from_trackers!(log, nil)
          Stat::Site::Minute.count.should eql(4)
          Stat::Site::Hour.count.should eql(2)
          Stat::Site::Day.count.should eql(2)
          Stat::Site::Minute.where(t: 'ovjigy83').before(Time.now).count.should eql(2)
          Stat::Site::Minute.where(t: 'ovjigy83', d: log.minute).first.bp.should eql({ "saf-osx" => 4 })
          Stat::Site::Day.where(t: 'ovjigy83', d: log.day).first.bp.should eql({ "saf-osx" => 8 })
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
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.e" => 1, "vlc" => 1, "bp.saf-osx" => 1, "md.f.d" => 1 }
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
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          :inc => { "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          :videos   => {
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
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
            "abcd1234" => { "vv.m" => 1, "vs.source12" => 1, "vvc" => 1 }
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
            "abcd1234" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1, "vv.m" => 1, "vvc" => 1, "vs.source12" => 1 },
            "efgh5678" => { "vl.m" => 2, "vl.e" => 1, "vlc" => 3, "bp.saf-osx" => 3, "md.h.d" => 2, "md.f.d" => 1 }
          }
        },
        "site1234"=> {
          :inc => {  "vv.i" => 1, "pv.m" => 3, "bp.saf-osx" => 3, "md.h.m" => 6 },
          :videos   => {
            "abcd1234" => { "vv.i" => 1, "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 },
            "efgh5678" => { "vl.m" => 3, "vlc" => 3, "bp.saf-osx" => 3, "md.h.m" => 3 }
          }
        }
      })}
    end

  end

end
