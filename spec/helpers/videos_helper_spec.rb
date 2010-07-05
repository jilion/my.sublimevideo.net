require 'spec_helper'

describe VideosHelper do
  
  describe "#duration" do
    it "should be 'No duration' if seconds is blank" do
      helper.duration(nil).should == 'No duration'
      helper.duration(Factory(:video, :duration => nil)).should == 'No duration'
      helper.duration(Factory(:video, :duration => '')).should == 'No duration'
    end
    
    it "should be 00:SS if seconds < 60" do
      helper.duration(Factory(:video, :duration => 35000)).should == '00:35'
    end
    
    it "should be MM:SS if seconds < 3600" do
      helper.duration(Factory(:video, :duration => 3525000)).should == '58:45'
    end
    
    it "should be HH:MM:SS if seconds > 3600" do
      helper.duration(Factory(:video, :duration => 3765000)).should == '01:02:45'
    end
  end
  
  describe "#uploaded_on" do
    it "should be '' if video is nil or has no created_at" do
      helper.uploaded_on(nil).should == ''
    end
    
    it "should format the creation date otherwise" do
      helper.uploaded_on(Factory(:video, :created_at => Time.now.utc)).should == "Uploaded on #{Time.now.utc.strftime('%d/%m/%Y')}"
    end
  end
  
  describe "#sizes_in_embed(video)" do
    it "should be [0,0] if video is nil" do
      helper.sizes_in_embed(nil).should == { :width => 0, :height => 0 }
    end
    
    it "should be the sizes of the encodings that has the max width if its width is under the preferred user embed width" do
      user      = Factory(:user, :video_settings => { :default_video_embed_width => 500 })
      video     = Factory(:video, :user => user, :width => 600, :height => 300)
      encoding1 = Factory(:video_encoding, :video => video, :width => 200, :height => 120)
      encoding2 = Factory(:video_encoding, :video => video, :width => 300, :height => 160)
      helper.sizes_in_embed(video).should == { :width => 300, :height => 160 }
    end
    
    it "should be the preferred user embed width and height proportioned with the sizes of the encodings that has the max width if its width is more than the preferred user embed width" do
      user      = Factory(:user, :video_settings => { :default_video_embed_width => 500 })
      video     = Factory(:video, :user => user, :width => 600, :height => 300)
      encoding1 = Factory(:video_encoding, :video => video, :width => 200, :height => 120)
      encoding2 = Factory(:video_encoding, :video => video, :width => 1200, :height => 160)
      helper.sizes_in_embed(video).should == { :width => 500, :height => (500*160)/1200 }
    end
  end
  
end