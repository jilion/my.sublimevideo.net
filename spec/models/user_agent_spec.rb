require 'spec_helper'
require 'timecop'

describe UserAgent do

  describe "validates" do
    [:token, :platforms, :browsers, :month].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:month) }
  end

  describe ".create_or_update_from_trackers!", :focus => true do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:logs_download).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz').and_return(logs_file)
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastUserAgents')
      %w[0w1o1q3c k8qaaj1l ibvjcopp hp1lepyq].each do |token|
        Factory(:site).update_attribute(:token, token)
      end
      UserAgent.create_or_update_from_trackers!(@log, @trackers)
    end

    let(:site) { Site.find_by_token('k8qaaj1l') }

    it { UserAgent.count.should == 5 }

    # describe "second referrer" do
    #   subject { Referrer.all.first }
    #
    #   it "should have valid attributes" do
    #     subject.url.should == 'http://www.killy.net/'
    #     subject.token.should == site.token
    #     subject.site_id.should == site.id
    #     subject.hits.should == 3
    #     subject.created_at.should be_present
    #     subject.updated_at.should be_present
    #   end
    #
    #   it "should update hits if same referrer reparsed" do
    #     Referrer.create_or_update_from_trackers!(@trackers)
    #
    #     subject.reload.hits.should == 6
    #     Referrer.count.should == 5
    #   end
    #
    #   it "should update updated_at on hits incrementation" do
    #     old_update_at = subject.updated_at
    #     Timecop.travel(Time.now + 1.minute)
    #
    #     Referrer.create_or_update_from_trackers!(@trackers)
    #
    #     subject.reload.updated_at.should_not <= old_update_at
    #   end
    # end
  end

end
