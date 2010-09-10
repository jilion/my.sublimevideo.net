require 'spec_helper'

describe Log::Voxcast do
  
  context "built with valid attributes" do
    before(:each) { VCR.insert_cassette('one_logs') }
    
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }
    
    it { should_not be_parsed }
    it { should be_valid }
    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "validates" do
    context "with already the same log in db" do
      before(:each) { VCR.insert_cassette('one_saved_logs') }
      
      it "should validate uniqueness of name" do
        Factory(:log_voxcast) 
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.errors[:name].should be_present
      end
      
      after(:each) { VCR.eject_cassette }
    end
  end
  
  context "created with valid attributes" do
    before(:each) { VCR.insert_cassette('one_saved_logs') }
    
    subject { Factory(:log_voxcast) }
    
    its(:created_at) { should be_present }
    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its("file.url")  { should == "/uploads/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz" }
    its("file.size") { should == 1149 }
    
    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end
    
    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end
    
    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end
    
    it "should delay parse_log after create" do
      subject # trigger log creation
      job = Delayed::Job.last
      job.name.should == 'Class#parse_log'
      job.priority.should == 20
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  context "created with valid attributes from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:logs_download).with('4076.voxcdn.com.log.1279103340-1279103400.gz').and_return(
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      )
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }
    
    its(:created_at) { should be_present }
    its(:hostname)   { should == '4076.voxcdn.com' }
    its("file.url")  { should == "/uploads/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz" }
    its("file.size") { should == 848 }
    
    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end
    
    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end
    
    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end
    
    it "should not delay parse_log after create" do
      subject # trigger log creation
      Delayed::Job.all.should be_empty
    end
  end
  
  describe "Class Methods" do
    it "should download and save new logs & launch delayed job" do
      VCR.use_cassette('multi_logs') do
        lambda { Log::Voxcast.fetch_download_and_create_new_logs }.should change(Log::Voxcast, :count).by(4)
        Delayed::Job.first.name.should == 'Class#fetch_download_and_create_new_logs'
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('multi_logs_with_already_existing_log') do
        Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274348520-1274348580.gz')
        lambda { Log::Voxcast.fetch_download_and_create_new_logs }.should change(Log::Voxcast, :count).by(3)
      end
    end
    
    it "should launch delayed fetch_download_and_create_new_logs" do
      lambda { Log::Voxcast.delay_fetch_download_and_create_new_logs }.should change(Delayed::Job, :count).by(1)
    end
    
    it "should not launch delayed fetch_download_and_create_new_logs if one pending already present" do
      Log::Voxcast.delay_fetch_download_and_create_new_logs
      lambda { Log::Voxcast.delay_fetch_download_and_create_new_logs }.should change(Delayed::Job, :count).by(0)
    end
    
    it "should have config values" do
      Log::Voxcast.config.should == {
        :file_format_class_name => "LogsFileFormat::Voxcast",
        :store_dir => "voxcast"
      }
    end
    
  end
  
end