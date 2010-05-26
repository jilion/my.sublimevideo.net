# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
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

describe Log do
  
  context "built with valid attributes" do
    before(:each) { VCR.insert_cassette('one_logs') }
    
    subject { Factory.build(:log, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }
    
    it { subject.should be_unprocessed                         }
    it { subject.should be_valid                               }
    it { subject.hostname.should   == 'cdn.sublimevideo.net'   }
    it { subject.started_at.should == Time.zone.at(1274773200) }
    it { subject.ended_at.should   == Time.zone.at(1274773260) }
    
    after(:each) { VCR.eject_cassette }
  end
  
  context "created with valid attributes" do
    before(:each) { VCR.insert_cassette('one_saved_logs') }
    
    subject { Factory(:log) }
    
    it "should have good log content" do
      log = Log.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end
    
    it "should parse and create usages!" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      subject.parse_and_create_usages!
    end
    
    it "should delay process after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Log#process'
      job.priority.should == 20
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Class Methods" do
    it "should download and save new logs & launch delayed job" do
      VCR.use_cassette('multi_logs') do
        lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(4)
        Delayed::Job.last.name.should == 'Class#download_and_save_new_logs'
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('multi_logs_with_already_existing_log') do
        Factory(:log, :name => 'cdn.sublimevideo.net.log.1274348520-1274348580.gz')
        lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(3)
      end
    end
    
    it "should launch delayed download_and_save_new_logs" do
      lambda { Log.delay_new_logs_download }.should change(Delayed::Job, :count).by(1)
    end
    
    it "should not launch delayed download_and_save_new_logs if one pending already present" do
      Log.delay_new_logs_download
      lambda { Log.delay_new_logs_download }.should change(Delayed::Job, :count).by(0)
    end
    
  end
  
end