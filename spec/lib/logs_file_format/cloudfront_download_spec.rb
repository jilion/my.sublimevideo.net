require 'spec_helper'

describe LogsFileFormat::CloudfrontDownload do
  
  describe "with E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::CloudfrontDownload')
    end
    
    it "should parse and return traffic_eu tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_eu }.first
      tracker.categories.should have(3).tokens
      tracker.categories["e14ab4de"][:sum].should == 134284
      tracker.categories["g46g16dz"][:sum].should == 3509835
      tracker.categories["313asa32"][:sum].should == 3696141
    end
    
    it "should parse and return requests_eu tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :requests_eu }.first
      tracker.categories.should have(3).tokens
      tracker.categories["e14ab4de"].should == 4
      tracker.categories["g46g16dz"].should == 5
      tracker.categories["313asa32"].should == 2
    end
    
    it "should parse and return hits tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :hits }.first
      tracker.categories.should have(3).tokens
      tracker.categories["e14ab4de"].should == 1
      tracker.categories["g46g16dz"].should == 1
      tracker.categories["313asa32"].should == 1
    end
  end
  
  describe "with E3KTK13341WJO.2010-06-24-23.t9E5stck.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-24-23.t9E5stck.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::CloudfrontDownload')
    end
    
    it "should parse and return traffic_eu tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_eu }.first
      tracker.categories.should have(1).tokens
      tracker.categories["k3zph1mc"][:sum].should == 56752792
    end
    
    it "should parse and return requests_eu tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :requests_eu }.first
      tracker.categories.should have(1).tokens
      tracker.categories["k3zph1mc"].should == 120
    end
    
    it "should parse and return hits tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :hits }.first
      tracker.categories.should have(1).tokens
      tracker.categories["k3zph1mc"].should == 6
    end
  end
  
end