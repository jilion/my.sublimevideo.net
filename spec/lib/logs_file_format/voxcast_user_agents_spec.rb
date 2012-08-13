require 'fast_spec_helper'
require 'request_log_analyzer'
require 'active_support/concern'
require 'active_support/core_ext'
require 'support/fixtures_helpers'
require File.expand_path('lib/log_analyzer')
require File.expand_path('lib/logs_file_format/voxcast_user_agents')

describe LogsFileFormat::VoxcastUserAgents do

  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastUserAgents')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :useragent }
      tracker.categories.should == {
       ["Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1", "ibvjcopp"] =>3
      }
    end
  end
end
