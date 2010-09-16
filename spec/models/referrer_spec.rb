require 'spec_helper'
require 'timecop'

describe Referrer do
  
  context "with a log & site already in db" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastReferrers')
      %w[0w1o1q3c k8qaaj1l ibvjcopp hp1lepyq].each do |token|
        Factory(:site).update_attribute(:token, token)
      end
      @site = Site.find_by_token('k8qaaj1l')
    end
    
    describe "create_or_update_from_trackers!" do
      before(:each) { Referrer.create_or_update_from_trackers!(@trackers) }
      
      it { Referrer.count.should == 5 }
      
      describe "second referrer" do
        subject { Referrer.all.second }
        
        its(:url)        { should == 'http://www.killy.net/' }
        its(:token)      { should == @site.token }
        its(:site_id)    { should == @site.id }
        its(:hits)       { should == 3 }
        its(:created_at) { should be_present }
        its(:updated_at) { should be_present }
        
        it "should update hits if same referrer reparsed" do
          Referrer.create_or_update_from_trackers!(@trackers)
          subject.reload.hits.should == 6
          Referrer.count.should == 5
        end
        
        it "should update updated_at on hits incrementation" do
          old_update_at = subject.updated_at
          Timecop.travel(Time.now + 1.minute)
          Referrer.create_or_update_from_trackers!(@trackers)
          subject.reload.updated_at.should_not <= old_update_at
        end
      end
    end
    
    describe "validations" do
      it "should validate url presence" do
        referrer = Factory.build(:referrer, :url => nil)
        referrer.should_not be_valid
        referrer.errors[:url].should be_present
      end
      
      it "should validate url format" do
        referrer = Factory.build(:referrer, :url => "-")
        referrer.should_not be_valid
        referrer.errors[:url].should be_present
      end
      
      it "should validate token presence" do
        referrer = Factory.build(:referrer, :token => nil)
        referrer.should_not be_valid
        referrer.errors[:token].should be_present
        referrer.errors[:site_id].should be_present
      end
    end
    
  end
end