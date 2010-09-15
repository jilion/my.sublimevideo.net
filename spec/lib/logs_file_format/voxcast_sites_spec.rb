require 'spec_helper'

describe LogsFileFormat::VoxcastSites do
  
  describe "with cdn.sublimevideo.net.log.1274798340-1274798400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1274798340-1274798400.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastSites')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "12345678" => 9 }
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["12345678"][:sum].should == 90986
    end
  end
  
  describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastSites')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "g3325oz4" => 3, "g8thugh6" => 1 }
    end
    
    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should == { "g8thugh6" => 7, "g3325oz4" => 3 }
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["g8thugh6"][:sum].should == 367093
      tracker.categories["g3325oz4"][:sum].should == 70696
    end
  end
  
  describe "with 4076.voxcdn.com.log.1279202700-1279202760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279202700-1279202760.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastSites')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "6vibplhv" => 1 }
    end
    
    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should be_empty
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 10460
    end
  end
  
  describe "with 4076.voxcdn.com.log.1279103340-1279103400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastSites')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should be_empty
    end
    
    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should be_empty
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 0
    end
  end
  
end