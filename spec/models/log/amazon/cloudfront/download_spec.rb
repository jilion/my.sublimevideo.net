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

describe Log::Amazon::Cloudfront::Download do
  before(:each) { VCR.insert_cassette('cloudfront/download/logs_list') }
  
  context "created with valid attributes" do
    subject { Factory(:log_cloudfront_download) }
    
    it { subject.usages.class_name.constantize.should == VideoUsage }
    it { subject.file.url.should == "/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz" }
    
    it "should have good log content" do
      log = Log::Amazon::Cloudfront::Download.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: date time x-edge-location")
      end
    end
     
    it "should parse and create usages from trackers on process" do
      VideoUsage.should_receive(:create_usages_from_trackers!)
      subject.process
    end
    
    it "should delay process after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Log::Amazon::Cloudfront::Download#process'
      job.priority.should == 20
    end
  end
  
  describe "Class Methods" do
    it "should launch delayed fetch_and_create_new_logs" do
      lambda { Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs }.should change(Delayed::Job.where(:handler.matches => "%fetch_and_create_new_logs%"), :count).by(1)
    end
    
    it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
      Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs
      lambda { Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      Log::Amazon::Cloudfront::Download.config.should == {
        :hostname => "v.sublimevideo.net",
        :file_format_class_name => "LogsFileFormat::CloudfrontDownload",
        :store_dir => "cloudfront/sublimevideo.videos/download/"
      }
    end
  end
  
  after(:each) { VCR.eject_cassette }
end