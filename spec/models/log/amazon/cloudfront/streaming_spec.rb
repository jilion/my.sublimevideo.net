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

describe Log::Amazon::Cloudfront::Streaming do
  
  context "created with valid attributes" do
    subject { Factory(:log_cloudfront_streaming) }
    
    it "should have good log url" do
      subject.file.url.should == "/uploads/cloudfront/sublimevideo.videos/streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz"
    end
    
    it "should have good log content" do
      log = Log::Amazon::Cloudfront::Streaming.find(subject.id) # to be sure that log is well saved with CarrierWave
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
      job.name.should == 'Log::Amazon::Cloudfront::Streaming#process'
      job.priority.should == 20
    end
  end
  
  describe "Class Methods" do
    it "should launch delayed fetch_and_create_new_logs" do
      lambda { Log::Amazon::Cloudfront::Streaming.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(1)
    end
    
    it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
      Log::Amazon::Cloudfront::Streaming.fetch_and_create_new_logs
      lambda { Log::Amazon::Cloudfront::Streaming.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      Log::Amazon::Cloudfront::Streaming.config.should == {
        :hostname => "s.sublimevideo.net",
        :file_format_class_name => "LogsFileFormat::CloudfrontStreaming",
        :store_dir => "cloudfront/sublimevideo.videos/streaming/"
      }
    end
  end
  
end