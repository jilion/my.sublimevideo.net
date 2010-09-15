require 'spec_helper'
require 'timecop'

describe Referer do
  
  context "with a log & site already in db" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastReferers')
      @site = Factory(:site)
      @site.update_attribute(:token, 'k8qaaj1l')
    end
    
    describe "create_or_update_from_trackers!" do
      before(:each) { Referer.create_or_update_from_trackers!(@trackers) }
      
      it { Referer.count.should == 7 }
      
      describe "second referer" do
        subject { Referer.all.second }
        
        its(:url)        { should == 'http://www.killy.net/' }
        its(:token)      { should == @site.token }
        its(:site_id)    { should == @site.id }
        its(:hits)       { should == 3 }
        its(:created_at) { should be_present }
        its(:updated_at) { should be_present }
        
        it "should update hits if same referer reparsed" do
          Referer.create_or_update_from_trackers!(@trackers)
          subject.reload.hits.should == 6
          Referer.count.should == 7
        end
        
        it "should update updated_at on hits incrementation" do
          old_update_at = subject.updated_at
          Timecop.travel(Time.now + 1.minute)
          Referer.create_or_update_from_trackers!(@trackers)
          subject.reload.updated_at.should_not <= old_update_at
        end
      end
    end
    
  end
  
end
