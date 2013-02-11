require 'fast_spec_helper'
require 'active_support/core_ext'
require 'request_log_analyzer'
require 'support/fixtures_helpers'

require 'services/log_analyzer'
require 'log_file_formats/amazon_log_file_format'
require 'log_file_formats/s3_licenses_log_file_format'

describe S3LicensesLogFileFormat do

  describe "with 2010-07-14-09-27-04-BAAC596FFB88F1D6 logs file" do
    before do
      log_file = fixture_file('logs/s3_licenses/2010-07-14-09-27-04-BAAC596FFB88F1D6')
      @trackers = LogAnalyzer.parse(log_file, 'S3LicensesLogFileFormat')
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
