require 'spec_helper'

describe SiteUsage do

  pending "with cdn.sublimevideo.net.log.1286528280-1286528340.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1286528280-1286528340.gz')
      CDN::VoxcastWrapper.stub(:download_log).with('cdn.sublimevideo.net.log.1286528280-1286528340.gz').and_return(log_file)
      @log = create(:log_voxcast, name: 'cdn.sublimevideo.net.log.1286528280-1286528340.gz', file: log_file)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::VoxcastSites')

      with_versioning do
        Timecop.travel(@log.started_at - 1.hour) do
          @site1 = create(:site, hostname: 'artofthetitle.com').tap { |s| s.token = 'ktfcm2l7'; s.save! }
        end
        @site1.hostname = 'bob.com'
        @site1.save!
      end

      @site2 = create(:site, user: @site1.user, hostname: 'sonymusic.se').tap { |s| s.token = 'mhud9lff'; s.save! }
    end

    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@log, @trackers).should == {
        traffic_voxcast: {"pvbj8rly"=>33528, "ot85lofm"=>110083, "mhud9lff"=>200134, "mimpia8j"=>181, "1nayz6hi"=>362, "ktfcm2l7"=>443482, "wbk2y56l"=>1988, "yekse1l8"=>361, "ibvjcopp"=>76498, "ocjeksk2"=>1976, "d73zpa3a"=>1988, "ccadedyg"=>4175, "j0lqevol"=>1977, "gsmhage0"=>78960, "ubaredbq"=>5964, "invxef8i"=>110017, "t5yhm4z1"=>117566, "mkjjb06j"=>1976, "pre0h6qx"=>81531, "nat10aym"=>1988, "iqa1kt1d"=>1988, "khgm2p4y"=>154983, "aov41s0h"=>1976, "fvkbs2ej"=>57743, "l6bza2zd"=>1987},
        loader_hits: {"mhud9lff"=>5, "1nayz6hi"=>2, "ktfcm2l7"=>7, "wbk2y56l"=>1, "yekse1l8"=>2, "ocjeksk2"=>1, "d73zpa3a"=>1, "j0lqevol"=>1, "gsmhage0"=>1, "ubaredbq"=>3, "mkjjb06j"=>1, "pre0h6qx"=>1, "nat10aym"=>1, "iqa1kt1d"=>1, "aov41s0h"=>1, "fvkbs2ej"=>1, "khgm2p4y"=>1, "l6bza2zd"=>1},
        main_player_hits: {"mhud9lff"=>2, "ktfcm2l7"=>5},
        player_hits: {"mhud9lff"=>3, "ktfcm2l7"=>6},
        main_player_hits_cached: {"mhud9lff"=>1, "ktfcm2l7"=>1},
        flash_hits: {"t5yhm4z1"=>1}
      }
    end

    it "should get tokens from trackers" do
      hbrs = SiteUsage.hits_traffic_and_requests_from(@log, @trackers)
      SiteUsage.tokens_from(hbrs).should include("ot85lofm")
      SiteUsage.tokens_from(hbrs).should include("mhud9lff")
      SiteUsage.tokens_from(hbrs).should include("ktfcm2l7")
      SiteUsage.tokens_from(hbrs).should include("ibvjcopp")
      SiteUsage.tokens_from(hbrs).should include("invxef8i")
      SiteUsage.tokens_from(hbrs).should include("t5yhm4z1")
      SiteUsage.tokens_from(hbrs).should include("gsmhage0")
      SiteUsage.tokens_from(hbrs).should include("pre0h6qx")
      SiteUsage.tokens_from(hbrs).should include("mhud9lff")
      SiteUsage.tokens_from(hbrs).should include("khgm2p4y")
      SiteUsage.tokens_from(hbrs).should include("ktfcm2l7")
      SiteUsage.tokens_from(hbrs).should include("fvkbs2ej")
    end

    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.site.should                       eq @site1
      usage.day.should                        eq Time.utc(2010,10,8)
      usage.loader_hits.should                eq 7
      usage.player_hits.should                eq 6
      usage.main_player_hits.should           eq 5
      usage.main_player_hits_cached.should    eq 1
      usage.extra_player_hits.should          eq 0
      usage.extra_player_hits_cached.should   eq 0
      usage.dev_player_hits.should            eq 0
      usage.dev_player_hits_cached.should     eq 0
      usage.invalid_player_hits.should        eq 0
      usage.invalid_player_hits_cached.should eq 0
      usage.flash_hits.should                 eq 0
      usage.requests_s3.should                eq 0
      usage.traffic_s3.should                 eq 0
      usage.traffic_voxcast.should            eq 443482
    end

    it "should increment existing entries" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usage = SiteUsage.where(site_id: @site1.id).first
      usage.main_player_hits.should eq 5
      usage.traffic_voxcast.should eq 443482

      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usage.reload.main_player_hits.should eq 5*2
      usage.traffic_voxcast.should eq 443482*2
    end

  end

  describe "with 4076.voxcdn.com.log.1308045840-1308045900.gz logs file" do
    let(:log_file) { fixture_file('logs/voxcast/4076.voxcdn.com.log.1308045840-1308045900.gz') }
    before do
      CDN::VoxcastWrapper.stub(:download_log).with('4076.voxcdn.com.log.1308045840-1308045900.gz').and_return(log_file)
      @log = create(:log_voxcast, name: '4076.voxcdn.com.log.1308045840-1308045900.gz', file: log_file)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::VoxcastSites')

      @site1 = create(:site, hostname: 'customerhub.net', wildcard: true).tap { |s| s.token = '9pfe3uop'; s.save }
      @site2 = create(:site, user: @site1.user, hostname: 'farmerswifeplay.com').tap { |s| s.token = '87r9xy5e'; s.save }
    end

    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@log, @trackers).should == {
        traffic_voxcast: { "9pfe3uop" => 143474, "87r9xy5e" => 5050 },
        loader_hits: { "9pfe3uop" => 2, "87r9xy5e" => 1 },
        main_player_hits_cached: { "9pfe3uop" => 2 },
        player_hits: { "9pfe3uop" => 3 },
        main_player_hits: { "9pfe3uop" => 1 },
        flash_hits: {},
        ssl_loader_hits: { "9pfe3uop" => 2, "87r9xy5e" => 1 }
      }
    end

    it "should get tokens from trackers" do
      hbrs = SiteUsage.hits_traffic_and_requests_from(@log, @trackers)
      SiteUsage.tokens_from(hbrs).should include("9pfe3uop")
      SiteUsage.tokens_from(hbrs).should include("87r9xy5e")
    end

    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.site.should                       eq @site1
      usage.day.should                        eq Time.utc(2011,6,14)
      usage.loader_hits.should                eq 2
      usage.ssl_loader_hits.should            eq 2
      usage.player_hits.should                eq 3
      usage.main_player_hits.should           eq 1
      usage.main_player_hits_cached.should    eq 2
      usage.extra_player_hits.should          eq 0
      usage.extra_player_hits_cached.should   eq 0
      usage.dev_player_hits.should            eq 0
      usage.dev_player_hits_cached.should     eq 0
      usage.invalid_player_hits.should        eq 0
      usage.invalid_player_hits_cached.should eq 0
      usage.flash_hits.should                 eq 0
      usage.requests_s3.should                eq 0
      usage.traffic_s3.should                 eq 0
      usage.traffic_voxcast.should            eq 143474
    end

  end

  describe "Trackers parsing with voxcast cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    let(:log_file) { fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz') }
    before do
      CDN::VoxcastWrapper.stub(:download_log).with('cdn.sublimevideo.net.log.1275002700-1275002760.gz').and_return(log_file)

      @site1 = create(:site, hostname: 'zeno.name').tap { |s| s.token = 'g3325oz4'; s.save }
      @site2 = create(:site, user: @site1.user, hostname: 'octavez.com').tap { |s| s.token = 'g8thugh6'; s.save }

      @log = create(:log_voxcast, file: log_file)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::VoxcastSites')
      Notify.should_receive(:send).any_number_of_times
    end

    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@log, @trackers).should == {
        traffic_voxcast: { "g8thugh6" => 367093, "g3325oz4" => 70696 },
        loader_hits: { "g8thugh6" => 1, "g3325oz4" => 3 },
        main_player_hits: { "g8thugh6" => 1, "g3325oz4" => 1 },
        player_hits: { "g8thugh6" => 7, "g3325oz4" => 3 },
        main_player_hits_cached: { "g3325oz4" => 2 },
        invalid_player_hits_cached: { "g8thugh6" => 1 },
        invalid_player_hits: { "g8thugh6" => 5 },
        flash_hits: {}
      }
    end

    it "should get tokens from trackers" do
      hbrs = SiteUsage.hits_traffic_and_requests_from(@log, @trackers)
      SiteUsage.tokens_from(hbrs).should eq ["g8thugh6", "g3325oz4"]
    end

    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.site.should                       eq @site1
      usage.day.should                        eq Time.utc(2010,5,27)
      usage.loader_hits.should                eq 3
      usage.player_hits.should                eq 3
      usage.main_player_hits.should           eq 1
      usage.main_player_hits_cached.should    eq 2
      usage.extra_player_hits.should          eq 0
      usage.extra_player_hits_cached.should   eq 0
      usage.dev_player_hits.should            eq 0
      usage.dev_player_hits_cached.should     eq 0
      usage.invalid_player_hits.should        eq 0
      usage.invalid_player_hits_cached.should eq 0
      usage.flash_hits.should                 eq 0
      usage.requests_s3.should                eq 0
      usage.traffic_s3.should                 eq 0
      usage.traffic_voxcast.should            eq 70696
    end
  end

  describe "Trackers parsing with s3 loaders" do
    before do
      @site1 = create(:site).tap { |s| s.token = 'gperx9p4'; s.save }
      @site2 = create(:site, user: @site1.user, hostname: 'google.com').tap { |s| s.token = 'pbgopxwy'; s.save }

      @log = create(:log_s3_loaders)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::S3Loaders')
    end

    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@log, @trackers).should == {
        requests_s3: { "fnhbfvkb" => 1, "7jbwuuni" => 1, "gperx9p4" => 1, "pbgopxwy" => 1, "6vibplhv" => 1, "ub4rrhk4" => 1 },
        traffic_s3: { "fnhbfvkb" => 734, "gperx9p4" => 727, "7jbwuuni" => 734, "pbgopxwy" => 734, "6vibplhv" => 734, "ub4rrhk4" => 734 }
      }
    end

    it "should get tokens from trackers" do
      hbrs = SiteUsage.hits_traffic_and_requests_from(@log, @trackers)
      SiteUsage.tokens_from(hbrs).should include("fnhbfvkb")
      SiteUsage.tokens_from(hbrs).should include("7jbwuuni")
      SiteUsage.tokens_from(hbrs).should include("gperx9p4")
      SiteUsage.tokens_from(hbrs).should include("pbgopxwy")
      SiteUsage.tokens_from(hbrs).should include("6vibplhv")
      SiteUsage.tokens_from(hbrs).should include("ub4rrhk4")
    end

    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.site.should            eq @site1
      usage.loader_hits.should     eq 0
      usage.player_hits.should     eq 0
      usage.flash_hits.should      eq 0
      usage.requests_s3.should     eq 1
      usage.traffic_s3.should      eq 727
      usage.traffic_voxcast.should eq 0
    end
  end
end
