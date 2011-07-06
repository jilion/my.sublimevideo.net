require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    it { should_not be_parsed }
    it { should_not be_referrers_parsed }
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        Factory(:log_voxcast)
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { Factory(:log_voxcast) }

    its(:created_at) { should be_present }
    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its("file.url")  { should == "/uploads/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz" }
    its("file.size") { should == 1149 }

    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log && parse_log_referrer after create" do
      subject # trigger log creation
      jobs = Delayed::Job.all.sort_by { |j| j.name }
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_user_agents'
      job.priority.should == 95
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_referrers'
      job.priority.should == 90
      job = jobs.pop
      job.name.should == 'Class#parse_log'
      job.priority.should == 20
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

    its(:created_at) { should be_present }
    its(:hostname)   { should == '4076.voxcdn.com' }
    its("file.url")  { should == "/uploads/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz" }
    its("file.size") { should == 848 }

    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log after create" do
      subject # trigger log creation
      Delayed::Job.all.should have(3).job
    end
  end

  describe "Class Methods" do
    describe ".fetch_download_and_create_new_logs" do
      it "should download and save new logs & launch delayed job" do
        VCR.use_cassette('multi_logs_fix') do
          lambda { Log::Voxcast.fetch_download_and_create_new_logs }.should change(Delayed::Job, :count).by(9)
          Delayed::Job.order(:created_at.asc).first.name.should == 'Class#fetch_download_and_create_new_logs'
        end
      end

      it "should download and only save news logs" do
        VCR.use_cassette('multi_logs_with_already_existing_log_fix') do
          Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274348520-1274348580.gz')
          lambda { Log::Voxcast.fetch_download_and_create_new_logs; @worker.work_off }.should change(Log::Voxcast, :count).by(3)
        end
      end
    end

    describe ".delay_download_and_create_new_logs" do
      it "should launch delayed fetch_download_and_create_new_logs" do
        lambda { Log::Voxcast.delay_download_and_create_new_logs }.should change(Delayed::Job, :count).by(1)
      end

      it "should not launch delayed fetch_download_and_create_new_logs if one pending already present" do
        Log::Voxcast.delay_download_and_create_new_logs
        lambda { Log::Voxcast.delay_download_and_create_new_logs }.should_not change(Delayed::Job, :count)
      end
    end

    it "should have config values" do
      Log::Voxcast.config.should == {
        :file_format_class_name => "LogsFileFormat::VoxcastSites",
        :store_dir => "voxcast"
      }
    end
  end

  describe "Instance Methods" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "parse_and_create_referrers!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        Referrer.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_referrers!
      end

      subject { @log }

      its(:referrers_parsed_at) { should be_present }

      it { should be_referrers_parsed }

      it "should not reparse if already done" do
        Referrer.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_referrers!
      end
    end

    describe "parse_and_create_user_agents!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_user_agents!
      end

      subject { @log }

      its(:user_agents_parsed_at) { should be_present }

      it { should be_user_agents_parsed }

      it "should not reparse if already done" do
        UsrAgent.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_user_agents!
      end
    end
  end

end
