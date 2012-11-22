require 'spec_helper'

describe Log::Amazon::S3::Loaders do
  use_vcr_cassette "s3/loaders/logs_list"
  let(:log_s3_loaders) { create(:log_s3_loaders) }

  context "Factory" do
    subject { log_s3_loaders }

    its("file.url") { should eq "/uploads/s3/sublimevideo.loaders/2010-07-14-09-22-26-63B226D3944909C8" }

    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.loaders")
    end

    it "should parse and create usages from trackers on parse_log" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
    end

    it "should delay parse_log after create" do
      Timecop.freeze do
        described_class.should delay(:parse_log, queue: 'low', at: 5.seconds.from_now.to_i).with('log_id')
        create(:log_s3_loaders, id: 'log_id')
      end
    end
  end

  describe "Class Methods" do
    describe ".config" do
      it "should have config values" do
        described_class.config.should == {
          hostname: "sublimevideo.loaders",
          file_format_class_name: "LogsFileFormat::S3Loaders",
          store_dir: "s3/sublimevideo.loaders/"
        }
      end
    end
  end

end
