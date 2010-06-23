require 'spec_helper'

describe VideosHelper do
  
  describe "#duration" do
    it "should be 'No duration' if seconds is blank" do
      duration(nil).should == 'No duration'
      duration(Factory(:video, :duration => nil)).should == 'No duration'
      duration(Factory(:video, :duration => '')).should == 'No duration'
    end
    
    it "should be 00:SS if seconds < 60" do
      duration(Factory(:video, :duration => 35000)).should == '00:35'
    end
    
    it "should be MM:SS if seconds < 3600" do
      duration(Factory(:video, :duration => 3525000)).should == '58:45'
    end
    
    it "should be HH:MM:SS if seconds > 3600" do
      duration(Factory(:video, :duration => 3765000)).should == '01:02:45'
    end
  end
  
  describe "#uploaded_on" do
    it "should be '' if video is nil or has no created_at" do
      uploaded_on(nil).should == ''
    end
    
    it "should format the creation date otherwise" do
      uploaded_on(Factory(:video, :created_at => Time.now)).should == "Uploaded on #{Time.now.strftime('%d/%m/%Y')}"
    end
  end
  
end