require 'spec_helper'

describe LogAnalyzer do
  
  describe "with cdn.sublimevideo.net.log.1274798340-1274798400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/cdn.sublimevideo.net.log.1274798340-1274798400.gz'))
      @trackers = LogAnalyzer.parse(logs_file)
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader }.first
      tracker.categories.should == { "/js/12345678.js" => 9 }
    end
  end
  
  describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/cdn.sublimevideo.net.log.1275002700-1275002760.gz'))
      @trackers = LogAnalyzer.parse(logs_file)
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader }.first
      tracker.categories.should == { "/js/g3325oz4.js" => 3, "/js/g8thugh6.js" => 1 }
    end
    
    it "should parse and return js tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player }.first
      tracker.categories.should == { "/p/sublime.js?t=g8thugh6" => 7, "/p/sublime.js?t=g3325oz4" => 3 }
    end
  end
  
end