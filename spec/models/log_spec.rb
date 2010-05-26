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
  
  context "with valid attributes" do
    before(:each) { VCR.insert_cassette('one_logs') }
    
    subject { Factory.build(:log, :name => 'cdn.sublimevideo.net.log.1274269140-1274269200.gz') }
    
    it { subject.should be_unprocessed                         }
    it { subject.should be_valid                               }
    it { subject.hostname.should   == 'cdn.sublimevideo.net'   }
    it { subject.started_at.should == Time.zone.at(1274269140) }
    it { subject.ended_at.should   == Time.zone.at(1274269200) }
    
    it "should have good log content" do
      subject.save
      log = Log.find(subject.id) # to be sure that log is saved
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: c-host c-identd")
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Class Methods" do
    it "should download and save new logs" do
      VCR.use_cassette('multi_logs') do
        lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(4)
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('multi_logs_with_already_existing_log') do
        Factory(:log, :name => 'cdn.sublimevideo.net.log.1274348520-1274348580.gz')
        lambda { Log.download_and_save_new_logs }.should change(Log, :count).by(3)
      end
    end
  end
  
end