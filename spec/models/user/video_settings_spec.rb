# == Schema Information
#
# Table name: users
#
#  video_settings :text
#

require 'spec_helper'

describe User::VideoSettings do
  context "with default video settings" do
    subject { Factory(:user) }
    
    its(:video_settings) { should == { :webm => "0", :default_video_embed_width => 600 } }
  end
  
  context "with given video settings" do
    subject { Factory(:user, :video_settings => { :webm => "1", :default_video_embed_width => 400 }) }
    
    its(:video_settings) { should == { :webm => "1", :default_video_embed_width => 400 } }
  end
  
  describe "callbacks" do
    it "should integerize default_video_embed_width" do
      Factory(:user, :video_settings => { :default_video_embed_width => "aaa" }).default_video_embed_width.should == 600
    end
    it "should set to the default default_video_embed_width if < 100" do
      Factory(:user, :video_settings => { :default_video_embed_width => "99" }).default_video_embed_width.should == 600
      Factory(:user, :video_settings => { :default_video_embed_width => "100" }).default_video_embed_width.should == 100
    end
  end
  
  describe "user instance methods extension" do
    describe "#use_webm?" do
      it "should be true if video_settings has :webm => true" do
        Factory(:user, :video_settings => { :webm => "1" }).should be_use_webm
      end
      
      it "should be false if video_settings has :webm => false" do
        Factory(:user, :video_settings => { :webm => "0" }).should_not be_use_webm
      end
    end
    
    describe "#default_video_embed_width" do
      it "should return the setting from video_settings hash" do
        Factory(:user, :video_settings => { :default_video_embed_width => 400 }).default_video_embed_width.should == 400
      end
    end
  end
  
end