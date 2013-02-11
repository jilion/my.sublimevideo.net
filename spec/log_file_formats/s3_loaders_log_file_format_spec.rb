require 'fast_spec_helper'
require 'active_support/core_ext'
require 'request_log_analyzer'
require 'support/fixtures_helpers'

require 'services/log_analyzer'
require 'log_file_formats/amazon_log_file_format'
require 'log_file_formats/s3_loaders_log_file_format'

describe S3LoadersLogFileFormat do

  describe "with 2010-07-14-09-22-26-63B226D3944909C8 logs file" do
    before do
      log_file = fixture_file('logs/s3_loaders/2010-07-14-09-22-26-63B226D3944909C8')
      @trackers = LogAnalyzer.parse(log_file, 'S3LoadersLogFileFormat')
    end

    it "should parse and return bandwith_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_s3 }.first
      tracker.categories.should have(6).tokens
      tracker.categories["ub4rrhk4"][:sum].should == 734
    end

    it "should parse and return requests_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :requests_s3 }.first
      tracker.categories.should have(6).tokens
      tracker.categories["ub4rrhk4"].should == 1
    end
  end

end
