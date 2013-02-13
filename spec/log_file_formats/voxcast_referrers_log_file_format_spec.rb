require 'fast_spec_helper'
require 'active_support/core_ext'
require 'request_log_analyzer'
require 'support/fixtures_helpers'

require 'services/log_analyzer'
require 'log_file_formats/voxcast_log_file_format'
require 'log_file_formats/voxcast_referrers_log_file_format'

describe VoxcastReferrersLogFileFormat do

  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(log_file, 'VoxcastReferrersLogFileFormat')
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
