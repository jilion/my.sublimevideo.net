require 'spec_helper'

describe UsrAgent do

  describe "Validations" do
    [:token, :platforms, :browsers, :month].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:month) }
  end

  describe ".create_or_update_from_trackers!" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz').and_return(log_file)
      @log = create(:log_voxcast, name: 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastUserAgents')
      create(:site).update_attribute(:token, 'ibvjcopp')
      UsrAgent.create_or_update_from_trackers!(@log, @trackers)
    end

    let(:site) { Site.find_by_token('ibvjcopp') }

    it { UsrAgent.count.should == 1 }

    describe "first usr_agent" do
      subject { UsrAgent.where(token: site.token).first }

      it "should have valid attributes" do
        subject.token.should == site.token
        subject.site.should eql(site)
        subject.month.should == Time.utc(2010,9,15).beginning_of_month
        subject.platforms.should == { "Macintosh" => { "Intel Mac OS X 10::6::8" => 3 } }
        subject.browsers.should == { "Safari" => { "platforms" => { "Macintosh" => 3 }, "versions" => { "5::0::5" => 3 } } }
      end

      it "should update hits if same usr_agent reparsed" do
        UsrAgent.create_or_update_from_trackers!(@log, @trackers)

        subject.reload.platforms.should == { "Macintosh" => { "Intel Mac OS X 10::6::8" => 6 } }
        subject.reload.browsers.should == { "Safari" => { "platforms" => { "Macintosh" => 6 }, "versions" => { "5::0::5" => 6 } } }
        UsrAgent.count.should == 1
      end
    end
  end

end
