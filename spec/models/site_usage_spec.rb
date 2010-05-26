# == Schema Information
#
# Table name: site_usages
#
#  id           :integer         not null, primary key
#  site_id      :integer
#  log_id       :integer
#  started_at   :datetime
#  ended_at     :datetime
#  license_hits :integer
#  js_hits      :integer
#  flash_hits   :integer
#  created_at   :datetime
#  updated_at   :datetime
#

require 'spec_helper'

describe SiteUsage do
  before(:each) { VCR.insert_cassette('one_saved_logs') }
  
  context "build with valid attributes" do
    subject { Factory.build(:site_usage) }
    
    it { subject.should be_valid          }
    it { subject.license_hits.should == 1 }
    it { subject.js_hits.should      == 1 }
    it { subject.flash_hits.should   == 1 }
    
  end
  
  context "saved with valid attributes" do
    subject { Factory(:site_usage) }
    
    it { subject.started_at.should == Time.zone.at(1274798340) }
    it { subject.ended_at.should   == Time.zone.at(1274798400) }
    
  end
  
  describe "Trackers parsing" do
    before(:each) do
      @site = Factory(:site)
      @site.token = '12345678'
      @site.save
      
      @log = Factory(:log)
      @trackers = LogAnalyzer.parse(@log.file)
    end
    
    it "should clean trackers" do
      SiteUsage.hits_from(@trackers).should == {
        :license => { "12345678" => 9 },
        :js      => {},
        :flash   => {}
      }
    end
    
    it "should get tokens from trackers" do
      hits = SiteUsage.hits_from(@trackers)
      SiteUsage.tokens_from(hits).should == ['12345678']
    end
    
    it "should create usages from trackers" do
      SiteUsage.create_usages_from_trackers!(@log, @trackers)
      usage = SiteUsage.last
      usage.log.should          == @log
      usage.site.should         == @site
      usage.license_hits.should == 9
    end
    
  end
  
  after(:each) { VCR.eject_cassette }
end
