require 'fast_spec_helper'
require 'active_support/core_ext'
require 'request_log_analyzer'
require 'support/fixtures_helpers'

require 'services/log_analyzer'
require 'log_file_formats/amazon_log_file_format'
require 'log_file_formats/s3_player_log_file_format'

describe S3PlayerLogFileFormat do

  describe "with 2010-07-16-05-22-13-8C4ECFE09170CCD5 logs file" do
    before do
      log_file = fixture_file('logs/s3_player/2010-07-16-05-22-13-8C4ECFE09170CCD5')
      @trackers = LogAnalyzer.parse(log_file, 'S3PlayerLogFileFormat')
    end

    it "should parse and return bandwith_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_s3 }.first
      tracker.categories.should have(1).tokens
      tracker.categories["6vibplhv"][:sum].should == 0
    end

    it "should parse and return requests_s3 tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :requests_s3 }.first
      tracker.categories.should have(1).tokens
      tracker.categories["6vibplhv"].should == 3
    end
  end

end
