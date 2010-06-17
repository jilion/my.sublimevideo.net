require 'spec_helper'

describe LogsFileFormat::CloudfrontDownload do
  
  describe "with E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::CloudfrontDownload')
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth }.first
      p tracker.categories
      # tracker.categories.should == { "/js/12345678.js" => 9 }
    end
  end
  
  # describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
  #   before(:each) do
  #     logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz'))
  #     @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
  #   end
  #   
  #   it "should parse and return license tracker" do
  #     tracker = @trackers.select { |tracker| tracker.options[:title] == :loader }.first
  #     tracker.categories.should == { "/js/g3325oz4.js" => 3, "/js/g8thugh6.js" => 1 }
  #   end
  #   
  #   it "should parse and return js tracker" do
  #     tracker = @trackers.select { |tracker| tracker.options[:title] == :player }.first
  #     tracker.categories.should == { "/p/sublime.js?t=g8thugh6" => 7, "/p/sublime.js?t=g3325oz4" => 3 }
  #   end
  # end
  
end