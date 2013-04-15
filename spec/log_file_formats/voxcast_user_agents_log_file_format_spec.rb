require 'fast_spec_helper'
require 'active_support/core_ext'
require 'request_log_analyzer'
require 'support/fixtures_helpers'

require 'services/log_analyzer'
require 'log_file_formats/voxcast_log_file_format'
require 'log_file_formats/voxcast_user_agents_log_file_format'

describe VoxcastUserAgentsLogFileFormat do

  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(log_file, 'VoxcastUserAgentsLogFileFormat')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.find { |t| t.options[:title] == :useragent }
      tracker.categories.should == {
       ["Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1", "ibvjcopp"] =>3
      }
    end
  end
end
