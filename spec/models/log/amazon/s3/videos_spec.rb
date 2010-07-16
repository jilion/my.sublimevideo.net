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

describe Log::Amazon::S3::Videos do
  before(:each) { VCR.insert_cassette('s3/videos/logs_list') }
  
  context "created with valid attributes" do
    subject { Factory(:log_s3_videos) }
    
    it { subject.usages.class_name.constantize.should == VideoUsage }
    it { subject.file.url.should == "/uploads/s3/sublimevideo.videos/2010-06-23-08-20-45-DE5461BCB46DA093" }
    
    it "should have good log content" do
      log = Log::Amazon::S3::Videos.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.videos")
    end
     
    it "should parse and create usages from trackers on process" do
      VideoUsage.should_receive(:create_usages_from_trackers!)
      subject.process
    end
    
    it "should delay process after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Log::Amazon::S3::Videos#process'
      job.priority.should == 20
    end
  end
  
  describe "Class Methods" do
    it "should launch delayed fetch_and_create_new_logs" do
      lambda { Log::Amazon::S3::Videos.fetch_and_create_new_logs }.should change(Delayed::Job.where(:handler.matches => "%fetch_and_create_new_logs%"), :count).by(1)
    end
    
    it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
      Log::Amazon::S3::Videos.fetch_and_create_new_logs
      lambda { Log::Amazon::S3::Videos.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      Log::Amazon::S3::Videos.config.should == {
        :hostname => "sublimevideo.videos",
        :file_format_class_name => "LogsFileFormat::S3Videos",
        :store_dir => "s3/sublimevideo.videos/"
      }
    end
  end
  
  after(:each) { VCR.eject_cassette }
end