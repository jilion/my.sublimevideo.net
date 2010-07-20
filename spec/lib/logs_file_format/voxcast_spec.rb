require 'spec_helper'

describe LogsFileFormat::Voxcast do
  
  describe "class methods" do
    subject { described_class }
    
    ["p/sublime.swf?t=6vibplhv","/p/close_button.png?t=6vibplhv", "/p/ie/transparent_pixel.gif?t=6vibplhv", "/p/beta/sublime.js?t=6vibplhv&super=top", '/6vibplhv/posterframe.jpg', '/js/6vibplhv/posterframe.js', '/js/6vibplhv.js', '/l/6vibplhv.js'].each do |path|
      it "should return token_from #{path}" do
        subject.token_from(path).should == "6vibplhv"
      end
      it "#{path} should be a token" do
        subject.token?(path).should be_true
      end
    end
    
    ['/p/ie/transparent_pixel.gif HTTP/1.1', "/sublime.js?t=6vibp", "/sublime_css.js?t=6vibplhv21"].each do |path|
      it "should not return token_from #{path}" do
        subject.token_from(path).should be_nil
      end
      it "#{path} should not be a player token" do
        subject.token?(path).should be_false
      end
    end
  end
  
  describe "with cdn.sublimevideo.net.log.1274798340-1274798400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1274798340-1274798400.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "12345678" => 9 }
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth_voxcast }.first
      tracker.categories["12345678"][:sum].should == 90986
    end
  end
  
  describe "with cdn.sublimevideo.net.log.1275002700-1275002760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "g3325oz4" => 3, "g8thugh6" => 1 }
    end
    
    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should == { "g8thugh6" => 7, "g3325oz4" => 3 }
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth_voxcast }.first
      tracker.categories["g8thugh6"][:sum].should == 367093
      tracker.categories["g3325oz4"][:sum].should == 70696
    end
  end
  
  describe "with 4076.voxcdn.com.log.1279202700-1279202760.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279202700-1279202760.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
    end
    
    it "should parse and return loader tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :loader_hits }.first
      tracker.categories.should == { "6vibplhv" => 1 }
    end
    
    it "should parse and return player tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :player_hits }.first
      tracker.categories.should be_empty
    end
    
    it "should parse and return bandwidth tracker" do
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 10460
    end
  end
  
  describe "with 4076.voxcdn.com.log.1279103340-1279103400.gz logs file" do
    before(:each) do
      logs_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      @trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::Voxcast')
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
      tracker = @trackers.select { |tracker| tracker.options[:title] == :bandwidth_voxcast }.first
      tracker.categories["6vibplhv"][:sum].should == 0
    end
  end
  
end