require 'spec_helper'

describe LogsFileFormat::VoxcastUserAgents do

  describe "with cdn.sublimevideo.net.log.1284549900-1284549960.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastUserAgents')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :useragent }
      tracker.categories.should == {
        ["Mozilla/5.0 (Windows; U; Windows NT 6.1; fr-FR) AppleWebKit/533.18.1 (KHTML, like Gecko) Version/5.0.2 Safari/533.18.5\" - \"Amsterdam", "k8qaaj1l"] => 4,
        ["Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.18.1 (KHTML, like Gecko) Version/5.0.2 Safari/533.18.5\" - \"Amsterdam", "cjbace0k"] => 1,
        ["Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.126 Safari/533.4\" - \"Singapore", "zf8jbler"] => 1,
        ["Mozilla/5.0 (Windows; U; Windows NT 6.1; de; rv:1.9.2.9) Gecko/20100824 Firefox/3.6.9\" - \"Amsterdam", "ibvjcopp"] => 1,
        ["Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7\" - \"San Jose", "hp1lepyq"] => 1,
        ["Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.19) Gecko/2010031218 Firefox/3.0.19\" - \"Amsterdam", "0w1o1q3c"] => 1,
        ["Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; InfoPath.1)\" - \"Amsterdam", "0w1o1q3c"] => 1,
        ["Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; nl-nl) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16\" - \"New York", "ibvjcopp"] => 1
      } 
    end
  end
end