require 'spec_helper'

describe Log::Amazon::S3::Player do
  use_vcr_cassette "s3/player/logs_list"
  let(:log_s3_player) { create(:log_s3_player) }

  context "Factory" do
    subject { log_s3_player }

    its(:hostname)   { should eq 'sublimevideo.player' }
    its(:started_at) { should eq Time.zone.parse('2010-07-16-05-22-13').utc }
    its(:ended_at)   { should eq (Time.zone.parse('2010-07-16-05-22-13') + 1.day).utc }
    its(:parsed_at)  { should be_nil}

    it { should_not be_parsed_at }
    it { should be_valid }
  end

  context "created with valid attributes" do
    subject { log_s3_player }

    its("file.url") { should eq "/uploads/s3/sublimevideo.player/2010-07-16-05-22-13-8C4ECFE09170CCD5" }

    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.player")
    end

    it "should parse and create usages from trackers on parse_log" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Amazon::S3::Player.parse_log(subject.id)
    end

    it "should delay parse_log after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should eq 'Class#parse_log'
      job.priority.should eq 20
    end
  end

  describe "Class Methods" do
    describe ".fetch_and_create_new_logs" do
      it "delays fetch_and_create_new_logs only once" do
        -> { 2.times { described_class.fetch_and_create_new_logs } }.should delay('%fetch_and_create_new_logs%')
      end
    end

    describe ".config" do
      it "should have config values" do
        described_class.config.should == {
          hostname: "sublimevideo.player",
          file_format_class_name: "LogsFileFormat::S3Player",
          store_dir: "s3/sublimevideo.player/"
        }
      end
    end
  end

end
