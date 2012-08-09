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
      Log::Amazon::S3::Loaders.parse_log(subject.id)
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
      it "should launch delayed fetch_and_create_new_logs" do
        expect { described_class.fetch_and_create_new_logs }.to change(Delayed::Job.where { handler =~ "%fetch_and_create_new_logs%" }, :count).by(1)
      end

      it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
        described_class.fetch_and_create_new_logs
        expect { described_class.fetch_and_create_new_logs }.to_not change(Delayed::Job, :count)
      end
    end

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
