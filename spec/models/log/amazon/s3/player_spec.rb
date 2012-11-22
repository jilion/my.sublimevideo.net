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
      described_class.parse_log(subject.id)
    end

    it "should delay parse_log after create" do
      Timecop.freeze do
        described_class.should delay(:parse_log, queue: 'low', at: 5.seconds.from_now.to_i).with('log_id')
        create(:log_s3_player, id: 'log_id')
      end
    end
  end

  describe "Class Methods" do
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
