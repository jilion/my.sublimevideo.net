# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  name       :string(255)
#  hostname   :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Log::CloudfrontDownload do
  
  before(:all) do
    unless File.exist?('public/uploads/cloudfront/')
      Dir.mkdir('public/uploads/cloudfront/')
      Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/')
      Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/download/')
    end
    unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz')
      FileUtils.cp(
        Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'),
        Rails.root.join('public/uploads/cloudfront/sublimevideo.videos/download/')
      )
    end
  end
  
  context "built with valid attributes" do
    subject { Factory.build(:log_cloudfront_download, :name => 'E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz') }
    
    it { should be_unprocessed }
    it { should be_valid }
    its(:ended_at)   { should == Time.zone.parse('2010-06-16') + 9.hours }
    
    it "should set hostname from logs.yml before_validation" do
      should be_valid
      subject.hostname == Log::CloudfrontDownload.config[:hostname]
    end
    it "should set file from name and bypass CarrierWave" do
      should be_valid
      subject.read_attribute(:file) == 'E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'
    end
  end
  
  context "created with valid attributes" do
    subject { Factory(:log_cloudfront_download) }
    
    it "should have good log url" do
      subject.file.url.should == "/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz"
    end
    
    it "should have good log content" do
      log = Log::CloudfrontDownload.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: date time x-edge-location")
      end
    end
     
    pending "should parse and create usages!" do
      # SiteUsage.should_receive(:create_usages_from_trackers!)
      # subject.parse_and_create_usages!
    end
    
    it "should delay process after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Log::CloudfrontDownload#process'
      job.priority.should == 20
    end
  end
  
  describe "Class Methods" do
    it "should download and save new logs & launch delayed job" do
      VCR.use_cassette('s3/logs_bucket_with_prefix') do
        lambda { Log::CloudfrontDownload.fetch_and_create_new_logs }.should change(Log::CloudfrontDownload, :count).by(4)
        Delayed::Job.last.name.should == 'Class#fetch_and_create_new_logs'
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('s3/logs_bucket_with_prefix') do
        Factory(:log_cloudfront_download, :name => 'E3KTK13341WJO.2010-06-15-14.O5iQjgcX.gz')
        lambda { Log::CloudfrontDownload.fetch_and_create_new_logs }.should change(Log::CloudfrontDownload, :count).by(3)
      end
    end
    
    it "should launch delayed fetch_and_create_new_logs" do
      lambda { Log::CloudfrontDownload.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(1)
    end
    
    it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
      Log::CloudfrontDownload.fetch_and_create_new_logs
      lambda { Log::CloudfrontDownload.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      Log::CloudfrontDownload.config.should == {
        :hostname => "v.sublimevideo.net",
        :file_format_class_name => "LogsFileFormat::CloudfrontDownload",
        :store_dir => "cloudfront/sublimevideo.videos/download"
      }
    end
    
  end
  
end