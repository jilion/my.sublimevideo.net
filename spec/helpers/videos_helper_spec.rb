require 'spec_helper'

include VideosHelper

describe VideosHelper do
  
  it "is included in the helper object" do
    included_modules = (class << helper; self; end).send :included_modules
    included_modules.should include(VideosHelper)
  end
  
  describe "#milliseconds_to_duration" do
    it "should be 'No duration' if seconds is blank" do
      helper.seconds_to_duration(nil).should == 'No duration'
      helper.seconds_to_duration("").should == 'No duration'
    end
    
    it "should be 00:SS if seconds < 60" do
      helper.seconds_to_duration(35).should == '00:35'
    end
    
    it "should be MM:SS if seconds < 3600" do
      helper.seconds_to_duration(3525).should == '58:45'
    end
    
    it "should be HH:MM:SS if seconds > 3600" do
      helper.seconds_to_duration(3765).should == '01:02:45'
    end
  end
  
  describe "#seconds_to_duration" do
    it "should be 'No duration' if seconds is blank" do
      helper.milliseconds_to_duration(nil).should == 'No duration'
      helper.milliseconds_to_duration("").should == 'No duration'
    end
    
    it "should be 00:SS if seconds < 60" do
      helper.milliseconds_to_duration(35000).should == '00:35'
    end
    
    it "should be MM:SS if seconds < 3600" do
      helper.milliseconds_to_duration(3525000).should == '58:45'
    end
    
    it "should be HH:MM:SS if seconds > 3600" do
      helper.milliseconds_to_duration(3765000).should == '01:02:45'
    end
  end
  
end