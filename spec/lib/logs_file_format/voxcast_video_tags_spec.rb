require 'spec_helper'

describe LogsFileFormat::VoxcastVideoTags do

  describe "with cdn.sublimevideo.net.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1310993640-1310993700.gz'))
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastVideoTags')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :video_tags }
      tracker.categories.should == {
        "?t=12345678&h=d&e=s&pd=d&pm=f" => 1,
        "?t=ibvjcopp&h=m&e=s&pd=d&pm=h" => 1
      }
    end
  end

  describe "with 4076.voxcdn.com.log.1310993640-1310993700.gz logs file" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1310993640-1310993700.gz'))
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastVideoTags')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.detect { |t| t.options[:title] == :video_tags }
      tracker.categories.should == {
        "?t=ibvjcopp&h=m&e=s&pd=t&pm=h" => 1
      }
    end
  end

end
