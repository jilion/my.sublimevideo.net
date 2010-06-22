# == Schema Information
#
# Table name: site_usages
#
#  id          :integer         not null, primary key
#  site_id     :integer
#  log_id      :integer
#  started_at  :datetime
#  ended_at    :datetime
#  loader_hits :integer         default(0)
#  player_hits :integer         default(0)
#  flash_hits  :integer         default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe SiteUsage do
  before(:each) { VCR.insert_cassette('one_saved_logs') }
  
  context "build with valid attributes" do
    subject { Factory.build(:site_usage) }
    
    its(:loader_hits) { should == 0 }
    its(:player_hits) { should == 0 }
    its(:flash_hits)  { should == 0 }
    it { should be_valid }
  end
  
  context "saved with valid attributes" do
    subject { Factory(:site_usage) }
    
    its(:started_at) { should == Time.zone.at(1275002700) }
    its(:ended_at)   { should == Time.zone.at(1275002760) }
    
  end
  
  describe "Trackers parsing" do
    before(:each) do
      @site1 = Factory(:site)
      @site1.token = 'g3325oz4'
      @site1.save
      @site2 = Factory(:site, :user => @site1.user, :hostname => 'google.com')
      @site2.token = 'g8thugh6'
      @site2.save
      
      @log = Factory(:log_voxcast)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::Voxcast')
    end
    
    it "should clean trackers" do
      SiteUsage.hits_from(@trackers).should == {
        :loader => { "g3325oz4" => 1, "g8thugh6" => 1},
        :player => { "g3325oz4" => 1, "g8thugh6" => 6},
        :flash  => {}
      }
    end
    
    it "should get tokens from trackers" do
      hits = SiteUsage.hits_from(@trackers)
      SiteUsage.tokens_from(hits).should == ["g3325oz4", "g8thugh6"]
    end
    
    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usage = SiteUsage.first
      usage.log.should          == @log
      usage.site.should         == @site1
      usage.loader_hits.should  == 1
      usage.player_hits.should  == 1
      usage.flash_hits.should   == 0
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
