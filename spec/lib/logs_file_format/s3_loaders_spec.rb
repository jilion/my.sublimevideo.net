require 'fast_spec_helper'
require 'request_log_analyzer'
require 'active_support/concern'
require 'active_support/core_ext'
require 'support/fixtures_helpers'
require File.expand_path('lib/log_analyzer')
require File.expand_path('lib/logs_file_format/s3_loaders')

describe LogsFileFormat::S3Loaders do

  describe "with 2010-07-14-09-22-26-63B226D3944909C8 logs file" do
    before do
      log_file = fixture_file('logs/s3_loaders/2010-07-14-09-22-26-63B226D3944909C8')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::S3Loaders')
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
