require 'spec_helper'

describe LogsFileFormat::S3Videos do
  
  describe "with 2010-06-23-08-20-45-DE5461BCB46DA093 logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/s3_videos/2010-06-23-08-20-45-DE5461BCB46DA093'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::S3Videos')
    end
    
    it "should parse and return bandwith tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth }.first
      tracker.categories.should have(1).tokens
      tracker.categories["4e1az9e5"][:sum].should == 33001318
    end
  end
  
end