require 'fast_spec_helper'
require 'request_log_analyzer'
require 'active_support/concern'
require 'active_support/core_ext'
require 'support/fixtures_helpers'
require File.expand_path('lib/log_analyzer')
require File.expand_path('lib/logs_file_format/voxcast_sites')

describe LogsFileFormat::VoxcastSites do

  describe "with cdn.sublimevideo.net.log.1274798340-1274798400.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1274798340-1274798400.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastSites')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { ["12345678", "-"] => 9 }
    end

    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["12345678"][:sum].should == 90986
    end
  end

  describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastSites')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { ["g8thugh6", "http://octavez.com/tmp/sv.html"] => 1, ["g3325oz4", "http://zeno.name/sv.html"] => 3 }
    end

    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should == {
        ["g8thugh6", 200, "http://octavez.com/tmp/sv.html"] => 1,
        ["g3325oz4", 304, "http://zeno.name/sv.html"]       => 2,
        ["g8thugh6", 304, "-"]                              => 1,
        ["g8thugh6", 200, "-"]                              => 5,
        ["g3325oz4", 200, "http://zeno.name/sv.html"]       => 1
      }
    end

    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["g8thugh6"][:sum].should == 367093
      tracker.categories["g3325oz4"][:sum].should == 70696
    end
  end

  describe "with cdn.sublimevideo.net.log.1286528280-1286528340.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1286528280-1286528340.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastSites')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories[["mhud9lff", "http://www.sonymusic.se/hurts"]].should == 5
    end

    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should == {
        ["ot85lofm", 200, "http://kriteachings.org/"]                                 => 1,
        ["mhud9lff", 200, "http://www.sonymusic.se/hurts"]                            => 2,
        ["ktfcm2l7", 200, "http://www.artofthetitle.com/"]                            => 5,
        ["ibvjcopp", 200, "http://sublimevideo.net/demo"]                             =>1,
        ["invxef8i", 200, "http://xyo.me/1158/tetris-le-film"]                        =>1,
        ["t5yhm4z1", 200, "http://seegno.com/blog/2010/07/07/building-the-workspace"] =>1,
        ["gsmhage0", 200, "http://www.auditoire.com/web/"]                            =>1,
        ["pre0h6qx", 200, "http://avidscreencast.com/"]                               =>1,
        ["mhud9lff", 304, "http://www.sonymusic.se/hurts"]                            =>1,
        ["khgm2p4y", 200, "http://www.liquid-concept.ch/"]                            =>2,
        ["ktfcm2l7", 304, "http://www.artofthetitle.com/"]                            =>1,
        ["fvkbs2ej", 200, "http://paulrouget.com/"]                                   =>1
      }
    end
  end

  describe "with 4076.voxcdn.com.log.1279202700-1279202760.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/4076.voxcdn.com.log.1279202700-1279202760.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastSites')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { ["6vibplhv", "-"] => 1 }
    end

    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should be_empty
    end

    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 10460
    end
  end

  describe "with 4076.voxcdn.com.log.1279103340-1279103400.gz logs file" do
    before do
      log_file = fixture_file('logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz')
      @trackers = LogAnalyzer.parse(log_file, 'LogsFileFormat::VoxcastSites')
    end

    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should be_empty
    end

    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should be_empty
    end

    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :traffic_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 0
    end
  end

end
