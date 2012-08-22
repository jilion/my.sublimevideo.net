require 'fast_spec_helper'
require 'request_log_analyzer'
require 'support/fixtures_helpers'
require File.expand_path('lib/log_analyzer')
require File.expand_path('lib/logs_file_format/voxcast_referrers')

describe LogsFileFormat::VoxcastReferrers do

  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastReferrers')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :referrers }
      tracker.categories.should == {
        ["http://www.sublimevideo.net/demo", "ibvjcopp"] => 1,
        ["http://sublimevideo.net/demo", "ibvjcopp"] => 2
      }
    end
  end

end
