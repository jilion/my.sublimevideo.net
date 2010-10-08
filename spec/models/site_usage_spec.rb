require 'spec_helper'

describe SiteUsage do
  before(:each) { VCR.insert_cassette('one_saved_logs') }
  
  context "build with valid attributes" do
    subject { Factory.build(:site_usage) }
    
    its(:loader_hits)                { should == 0 }
    its(:player_hits)                { should == 0 }
    its(:main_player_hits)           { should == 0 }
    its(:main_player_hits_cached)    { should == 0 }
    its(:dev_player_hits)            { should == 0 }
    its(:dev_player_hits_cached)     { should == 0 }
    its(:invalid_player_hits)        { should == 0 }
    its(:invalid_player_hits_cached) { should == 0 }
    its(:flash_hits)                 { should == 0 }
    it { should be_valid }
  end
  
  context "saved with valid attributes" do
    subject { Factory(:site_usage) }
    
    its(:started_at) { should == Time.at(1275002700).utc }
    its(:ended_at)   { should == Time.at(1275002760).utc }
  end
  
  describe "Trackers parsing with voxcast" do
    before(:each) do
      @site1 = Factory(:site, :hostname => 'zeno.name')
      @site1.token = 'g3325oz4'
      @site1.save
      @site2 = Factory(:site, :user => @site1.user, :hostname => 'octavez.com')
      @site2.token = 'g8thugh6'
      @site2.save
      
      @log = Factory(:log_voxcast)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::VoxcastSites')
    end
    
    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@trackers).should == { 
        :traffic_voxcast => { "g8thugh6" => 367093, "g3325oz4" => 70696 },
        :loader_hits => { "g8thugh6" => 1, "g3325oz4" => 3 },
        :main_player_hits => { "g8thugh6" => 1, "g3325oz4" => 1 },
        :player_hits => { "g8thugh6" => 7, "g3325oz4" => 3 },
        :main_player_hits_cached => { "g3325oz4" => 2 },
        :invalid_player_hits_cached => { "g8thugh6" => 1 },
        :invalid_player_hits => { "g8thugh6" => 5 },
        :flash_hits => {}
      }
    end
    
    it "should get tokens from trackers" do
      hbr = SiteUsage.hits_traffic_and_requests_from(@trackers)
      SiteUsage.tokens_from(hbr).should == ["g8thugh6", "g3325oz4"]
    end
    
    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.log.should                        == @log
      usage.site.should                       == @site1
      usage.loader_hits.should                == 3
      usage.player_hits.should                == 3
      usage.main_player_hits.should           == 1
      usage.main_player_hits_cached.should    == 2
      usage.dev_player_hits.should            == 0
      usage.dev_player_hits_cached.should     == 0
      usage.invalid_player_hits.should        == 0
      usage.invalid_player_hits_cached.should == 0
      usage.flash_hits.should                 == 0
      usage.requests_s3.should                == 0
      usage.traffic_s3.should                 == 0
      usage.traffic_voxcast.should            == 70696
    end
  end
  
  describe "Trackers parsing with s3 loaders" do
    before(:each) do
      @site1 = Factory(:site)
      @site1.token = 'gperx9p4'
      @site1.save
      @site2 = Factory(:site, :user => @site1.user, :hostname => 'google.com')
      @site2.token = 'pbgopxwy'
      @site2.save
      
      @log = Factory(:log_s3_loaders)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::S3Loaders')
    end
    
    it "should clean trackers" do
      SiteUsage.hits_traffic_and_requests_from(@trackers).should == {
        :requests_s3=>{"fnhbfvkb"=>1, "7jbwuuni"=>1, "gperx9p4"=>1, "pbgopxwy"=>1, "6vibplhv"=>1, "ub4rrhk4"=>1},
        :traffic_s3=>{"fnhbfvkb"=>734, "gperx9p4"=>727, "7jbwuuni"=>734, "pbgopxwy"=>734, "6vibplhv"=>734, "ub4rrhk4"=>734}
      }
    end
    
    it "should get tokens from trackers" do
      hbr = SiteUsage.hits_traffic_and_requests_from(@trackers)
      SiteUsage.tokens_from(hbr).should include("fnhbfvkb")
      SiteUsage.tokens_from(hbr).should include("7jbwuuni")
      SiteUsage.tokens_from(hbr).should include("gperx9p4")
      SiteUsage.tokens_from(hbr).should include("pbgopxwy")
      SiteUsage.tokens_from(hbr).should include("6vibplhv")
      SiteUsage.tokens_from(hbr).should include("ub4rrhk4")
    end
    
    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usages = SiteUsage.all
      usages.map(&:site).should include(@site1)
      usages.map(&:site).should include(@site2)
      usage = usages.select { |u| u.site == @site1 }.first
      usage.log.should               == @log
      usage.site.should              == @site1
      usage.loader_hits.should       == 0
      usage.player_hits.should       == 0
      usage.flash_hits.should        == 0
      usage.requests_s3.should       == 1
      usage.traffic_s3.should      == 727
      usage.traffic_voxcast.should == 0
    end
  end
  
  describe "Callbacks" do
    before(:each) { @site = Factory(:site) }
    
    it "should update site.loader_hits_cache" do
      lambda { Factory(:site_usage, :site => @site, :loader_hits => 2) }.should change { @site.reload.loader_hits_cache }.by(2)
    end
    it "should update site.player_hits_cache" do
      lambda { Factory(:site_usage, :site => @site, :player_hits => 2) }.should change { @site.reload.player_hits_cache }.by(2)
    end
    it "should update site.flash_hits_cache" do
      lambda { Factory(:site_usage, :site => @site, :flash_hits => 2) }.should change { @site.reload.flash_hits_cache }.by(2)
    end
    
  end
  
  after(:each) { VCR.eject_cassette }
end
