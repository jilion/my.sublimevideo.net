require 'spec_helper'

describe LogsFileFormat::CloudfrontStreaming do
  
  describe "with EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/cloudfront_streaming/EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::CloudfrontStreaming')
    end
    
    it "should parse and return bandwidth_eu tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth_eu }.first
      tracker.categories.should have(1).tokens
      tracker.categories["4e1az9e5"][:sum].should == 51858524
    end
    
    it "should parse and return hits tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :hits }.first
      tracker.categories.should have(1).tokens
      tracker.categories["4e1az9e5"].should == 5
    end
  end
  
end