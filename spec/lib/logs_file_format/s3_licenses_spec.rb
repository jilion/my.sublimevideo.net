require 'fast_spec_helper'
require 'request_log_analyzer'
require 'active_support/concern'
require 'active_support/core_ext'
require 'support/fixtures_helpers'
require File.expand_path('lib/log_analyzer')
require File.expand_path('lib/logs_file_format/s3_licenses')

describe "LogsFileFormat::S3Licenses" do

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
