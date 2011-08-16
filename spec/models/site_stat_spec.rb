require 'spec_helper'

describe SiteStat do

  context "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      @log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1313499060-1313499120.gz'))
      log_time  = 5.days.ago.change(sec: 0).to_i
      @log      = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{log_time}-#{log_time + 60}.gz", file: @log_file)
      @trackers = @log.trackers('LogsFileFormat::VoxcastStats')
    end

    describe ".delay_clear_old_minutes_and_days_stats" do
      it "delays clear_old_minutes_and_days_stats if not already delayed" do
        expect { SiteStat.delay_clear_old_minutes_and_days_stats }.to change(Delayed::Job, :count).by(1)
        Delayed::Job.last.run_at.should be_within(60).of(15.minutes.from_now)
      end

      it "delays nothing if already delayed" do
        SiteStat.delay_clear_old_minutes_and_days_stats
        expect { SiteStat.delay_clear_old_minutes_and_days_stats }.to change(Delayed::Job, :count).by(0)
      end
    end

    describe ".clear_old_minutes_and_days_stats" do
      it "delete old minutes and days site stats, but keep all stats" do
        SiteStat.create_stats_from_trackers!(@log, @trackers)
        log = Factory.build(:log_voxcast, name: "cdn.sublimevideo.net.log.#{1.minute.ago.change(sec: 0).to_i}-#{Time.now.utc.change(sec: 0).to_i}.gz", file: @log_file)
        SiteStat.create_stats_from_trackers!(log, @trackers)
        SiteStat.count.should eql(6)
        SiteStat.m_before(180.minutes.ago).count.should eql(1)
        SiteStat.h_before(72.hours.ago).count.should eql(1)
        SiteStat.clear_old_minutes_and_days_stats
        SiteStat.count.should eql(4)
        SiteStat.m_before(180.minutes.ago).count.should eql(0)
        SiteStat.h_before(72.hours.ago).count.should eql(0)
      end

      it "delays itself" do
        expect { SiteStat.clear_old_minutes_and_days_stats }.to change(Delayed::Job, :count).by(1)
        Delayed::Job.last.run_at.should be_within(60).of(15.minutes.from_now)
      end
    end

    describe ".create_stats_from_trackers!" do
      it "create three stats m/h/d for each token" do
        SiteStat.create_stats_from_trackers!(@log, @trackers)
        SiteStat.count.should eql(3)
        SiteStat.where(t: 'ovjigy83', m: @log.minute).should be_present
        SiteStat.where(t: 'ovjigy83', h: @log.hour).should be_present
        SiteStat.where(t: 'ovjigy83', d: @log.day).should be_present
      end

      it "update existing h/d stats" do
        SiteStat.create_stats_from_trackers!(@log, @trackers)
        log = Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1310993700-1310993760.gz', file: @log_file)
        SiteStat.create_stats_from_trackers!(log, @trackers)
        SiteStat.count.should eql(6)
        SiteStat.where(t: 'ovjigy83').m_before(Time.now).count.should eql(2)
        SiteStat.where(t: 'ovjigy83', d: log.day).first.bp.should eql({ "saf-osx" => 1, "chr-osx" => 1, "fir-osx" => 1 })
      end
    end

    describe ".incs_from_trackers" do
      it "returns incs for each token" do
        SiteStat.incs_from_trackers(@trackers).should eql({
          "ovjigy83" => { "pv.m" => 3, "bp.saf-osx" => 1, "md.h.d" => 3, "bp.chr-osx" => 1, "bp.fir-osx" => 1 }
        })
      end
    end
  end

  describe ".browser_and_platform_key" do
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1").should eql("saf-osx") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (X11; U; Linux amd64; rv:5.0) Gecko/20100101 Firefox/5.0 (Debian)").should eql("fir-lin") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET CLR 2.0.50727; Media Center PC 6.0)").should eql("iex-win") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.815.0 Safari/535.1").should eql("chr-win") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (Linux; U; Android 2.3.4; fr-fr; HTC Desire Build/GRJ22) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1").should eql("and-and") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (BlackBerry; U; BlackBerry 9700; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/6.0.0.546 Mobile Safari/534.8+").should eql("rim-rim") }
    specify { SiteStat.browser_and_platform_key("BlackBerry9700/5.0.0.862 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/120").should eql("rim-rim") }
    specify { SiteStat.browser_and_platform_key("Opera/9.80 (X11; Linux x86_64; U; Ubuntu/10.10 (maverick); pl) Presto/2.7.62 Version/11.01").should eql("ope-lin") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (webOS/1.0; U; en-US) AppleWebKit/525.27.1 (KHTML, like Geko) Version/1.0 Safari/525.27.1 Pre/1.0").should eql("weo-weo") }
    specify { SiteStat.browser_and_platform_key("Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0) Asus;Galaxy6").should eql("iex-wip") }
    specify { SiteStat.browser_and_platform_key("Lynx/2.8.7rel.2 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0a").should eql("oth-otd") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (X11; U; Linux armv7l; ru-RU; rv:1.9.2.3pre) Gecko/20100723 Firefox/3.5 Maemo Browser 1.7.4.8 RX-51 N900").should eql("fir-lin") }
    specify { SiteStat.browser_and_platform_key("Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (J2ME/23.377; U; en) Presto/2.5.25 Version/10.54").should eql("oth-otm") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543a Safari/419.3").should eql("saf-iph") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0(iPad; U; CPU OS 4_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F191 Safari/6533.18.5").should eql("saf-ipa") }
    specify { SiteStat.browser_and_platform_key("Mozilla/5.0(iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B314 Safari/531.21.10").should eql("saf-ipa") }
    specify { SiteStat.browser_and_platform_key("Mozila/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Geckto) Version/3.0 Mobile/3A101a Safari/419.3").should eql("saf-ipo") }
    specify { SiteStat.browser_and_platform_key("HotJava/1.1.2 FCS").should eql("oth-otd") }
    specify { SiteStat.browser_and_platform_key("").should eql("oth-otd") }
  end

end
