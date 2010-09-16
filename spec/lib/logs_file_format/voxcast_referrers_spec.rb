require 'spec_helper'

describe LogsFileFormat::VoxcastReferrers do
  
  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastReferrers')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :referrers }
      tracker.categories.should == {
        ["http://www.romainkedochim.com/blog/live-music/news-sublime-video-player-in-html5-first-test-with-clive-selwyn/", "0w1o1q3c"] => 2,
        ["http://www.killy.net/", "k8qaaj1l"] => 3,
        ["http://sublimevideo.net/demo", "ibvjcopp"] => 2,
        ["http://ben.mohu.local/", "cjbace0k"] => 1,
        ["http://www.killy.net/?paged=2", "k8qaaj1l"] => 1,
        ["http://pineapplepark.com.au/", "hp1lepyq"] => 1,
        ["http://capped.tv/xplsv-or_so_they_say", "zf8jbler"] => 1
      }
    end
  end
end