require 'spec_helper'

describe LogsFileFormat::S3Licenses do

  describe "with 2010-07-14-09-27-04-BAAC596FFB88F1D6 logs file" do
    before do
      log_file = fixture_file('logs/s3_licenses/2010-07-14-09-27-04-BAAC596FFB88F1D6')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::S3Licenses')
    end

    it "should parse and return bandwith_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_s3 }.first
      tracker.categories.should have(1).tokens
      tracker.categories["abcd1234"][:sum].should == 542
    end

    it "should parse and return requests_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :requests_s3 }.first
      tracker.categories.should have(1).tokens
      tracker.categories["abcd1234"].should == 1
    end
  end

end