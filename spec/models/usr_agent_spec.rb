require 'spec_helper'
require 'timecop'

describe UsrAgent do

  describe "Validations" do
    [:token, :platforms, :browsers, :month].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:month) }
  end

  describe ".create_or_update_from_trackers!" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz').and_return(logs_file)
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastUserAgents')
      %w[0w1o1q3c k8qaaj1l ibvjcopp hp1lepyq].each do |token|
        Factory(:site).update_attribute(:token, token)
      end
      UsrAgent.create_or_update_from_trackers!(@log, @trackers)
    end

    let(:site) { Site.find_by_token('k8qaaj1l') }

    it { UsrAgent.count.should == 4 }

    describe "first usr_agent" do
      subject { UsrAgent.where(:token => site.token).first }

      it "should have valid attributes" do
        subject.token.should == site.token
        subject.site_id.should == site.id
        subject.month.should == Time.utc(2010,9,15).beginning_of_month
        subject.platforms.should == { "Windows" => { "Windows 7" => 4 } }
        subject.browsers.should == { "Safari" =>{ "versions" => { "5::0::2" => 4 }, "platforms" => {"Windows" => 4 } } }
      end

      it "should update hits if same usr_agent reparsed" do
        UsrAgent.create_or_update_from_trackers!(@log, @trackers)

        subject.reload.platforms.should == { "Windows" => { "Windows 7" => 8 } }
        subject.reload.browsers.should == { "Safari" =>{ "versions" => { "5::0::2" => 8 }, "platforms" => {"Windows" => 8 } } }
        UsrAgent.count.should == 4
      end
    end
  end

end
