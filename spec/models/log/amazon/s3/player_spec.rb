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

describe Log::Amazon::S3::Player do
  before(:each) { VCR.insert_cassette('s3/player/logs_list') }
  
  context "created with valid attributes" do
    subject { Factory(:log_s3_player) }
    
    it { subject.usages.name.constantize.should == SiteUsage }
    it { subject.file.url.should == "/uploads/s3/sublimevideo.player/2010-07-16-05-22-13-8C4ECFE09170CCD5" }
    
    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      log.file.read.should include("sublimevideo.player")
    end
     
    it "should parse and create usages from trackers on process" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      subject.parse
    end
    
    it "should delay process after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Log::Amazon::S3::Player#process'
      job.priority.should == 20
    end
  end
  
  describe "Class Methods" do
    it "should launch delayed fetch_and_create_new_logs" do
      lambda { described_class.fetch_and_create_new_logs }.should change(Delayed::Job.where(:handler.matches => "%fetch_and_create_new_logs%"), :count).by(1)
    end
    
    it "should not launch delayed fetch_and_create_new_logs if one pending already present" do
      described_class.fetch_and_create_new_logs
      lambda { described_class.fetch_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      described_class.config.should == {
        :hostname => "sublimevideo.player",
        :file_format_class_name => "LogsFileFormat::S3Player",
        :store_dir => "s3/sublimevideo.player/"
      }
    end
  end
  
  after(:each) { VCR.eject_cassette }
end