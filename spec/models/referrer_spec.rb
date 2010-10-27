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
    end
    
    describe "create_or_update_from_trackers!" do
      before(:each) { Referrer.create_or_update_from_trackers!(@trackers) }
      
      let(:site)           { Site.find_by_token('k8qaaj1l') }
      let(:first_referrer) { Referrer.all.first }
      
      it { Referrer.count.should == 5 }
      
      describe "second referrer" do
        subject { first_referrer }
        
        its(:url)        { should == 'http://www.killy.net/' }
        its(:token)      { should == site.token }
        its(:site_id)    { should == site.id }
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
    
    describe "validates" do
      [:token, :url, :hits].each do |attr|
        it { should allow_mass_assignment_of(attr) }
      end
      
      it { should validate_presence_of(:url) }
      it { should validate_presence_of(:token) }
      
      it { should allow_value("http://rymai.com").for(:url) }
      it { should_not allow_value("-").for(:url) }
    end
    
  end
end