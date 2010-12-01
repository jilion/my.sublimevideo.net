require 'spec_helper'

describe LogsFileFormat::Voxcast do
  
  describe "Class Methods" do
    subject { LogsFileFormat::VoxcastSites }
    
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
  
end