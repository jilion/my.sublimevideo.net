require 'spec_helper'

describe LogsFileFormat::CloudfrontDownload do
  
  describe "with E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::CloudfrontDownload')
    end
    
    it "should parse and return license tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth }.first
      tracker.categories.should have(3).tokens
      tracker.categories["e14ab4de"][:sum].should == 134284
      tracker.categories["g46g16dz"][:sum].should == 3509835
      tracker.categories["313asa32"][:sum].should == 3696141
    end
  end
  
end