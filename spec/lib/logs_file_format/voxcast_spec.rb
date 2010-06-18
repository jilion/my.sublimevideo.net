require 'spec_helper'

describe LogsFileFormat::Voxcast do
  
  describe "with cdn.sublimevideo.net.log.1274798340-1274798400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1274798340-1274798400.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader }.first
      tracker.categories.should == { "12345678" => 9 }
    end
  end
  
  describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader }.first
      tracker.categories.should == { "g3325oz4" => 3, "g8thugh6" => 1 }
    end
    
    it "should parse and return js tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player }.first
      tracker.categories.should == { "g8thugh6" => 7, "g3325oz4" => 3 }
    end
  end
  
end