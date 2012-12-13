require 'spec_helper'

describe Log::Amazon::S3::Licenses do
  use_vcr_cassette "s3/licenses/logs_list"
  let(:log_s3_licenses) { create(:log_s3_licenses) }

  context "Factory" do
    subject { log_s3_licenses }

    its("file.url") { should eq "/uploads/s3/sublimevideo.licenses/2010-07-14-11-29-03-BDECA2599C0ADB7D" }

    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.licenses")
    end

    it "should parse and create usages from trackers on parse_log" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
    end

    it "should delay parse_log after create" do
      Timecop.freeze do
        described_class.should delay(:parse_log, queue: 'log', at: 5.seconds.from_now.to_i).with('log_id')
        create(:log_s3_licenses, id: 'log_id')
      end
    end
  end

  describe "Class Methods" do
    describe ".config" do
      it "should have config values" do
        described_class.config.should == {
          hostname: "sublimevideo.licenses",
          file_format_class_name: "LogsFileFormat::S3Licenses",
          store_dir: "s3/sublimevideo.licenses/"
        }
      end
    end
  end

end
