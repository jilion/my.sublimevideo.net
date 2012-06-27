require 'spec_helper'

describe Log::Amazon::S3::Licenses do
  use_vcr_cassette "s3/licenses/logs_list"
  let(:log_s3_licenses) { create(:log_s3_licenses) }

  context "Factory" do
    subject { log_s3_licenses }

    its("file.url") { should == "/uploads/s3/sublimevideo.licenses/2010-07-14-11-29-03-BDECA2599C0ADB7D" }

    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.licenses")
    end

    it "should parse and create usages from trackers on parse_log" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Amazon::S3::Licenses.parse_log(subject.id)
    end

    it "should delay parse_log after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Class#parse_log'
      job.priority.should == 20
    end
  end

  describe "Class Methods" do
    describe ".fetch_and_create_new_logs" do
      it "should launch delayed fetch_and_create_new_logs" do
        lambda { described_class.fetch_and_create_new_logs }.should change(Delayed::Job.where(:handler.matches => "%fetch_and_create_new_logs%"), :count).by(1)
      end

      it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
        described_class.fetch_and_create_new_logs
        lambda { described_class.fetch_and_create_new_logs }.should_not change(Delayed::Job, :count)
      end
    end

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
