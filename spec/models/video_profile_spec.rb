# == Schema Information
#
# Table name: video_profiles
#
#  id             :integer         not null, primary key
#  title          :string(255)
#  description    :text
#  name           :string(255)
#  extname        :string(255)
#  thumbnailable  :boolean
#  versions_count :integer         default(0)
#  created_at     :datetime
#  updated_at     :datetime
#

require 'spec_helper'

describe VideoProfile do
  
  context "with valid attributes" do
    subject { Factory(:video_profile) }
    
    its(:title)       { should be_present }
    its(:description) { should == ""      }
    its(:name)        { should == ""      }
    its(:extname)     { should be_present }
    
    it { should be_valid }
  end
  
  describe "Validations" do
    it "should validate presence of :title" do
      video_profile = Factory.build(:video_profile, :title => nil)
      video_profile.should_not be_valid
      video_profile.errors[:title].should be_present
    end
    it "should validate presence of :extname" do
      video_profile = Factory.build(:video_profile, :extname => nil)
      video_profile.should_not be_valid
      video_profile.errors[:extname].should be_present
    end
  end
  
  describe "State Machine" do
  end
  
  describe "Callbacks" do
    describe "before_create" do
      it "should set thumbnailable to false if not specified" do
        vp = Factory(:video_profile)
        vp.should be_valid
        vp.thumbnailable.should be_false
      end
      it "should not set thumbnailable to false if specified" do
        vp = Factory(:video_profile, :thumbnailable => true)
        vp.thumbnailable.should be_true
      end
    end
  end
  
  describe "Class Methods" do
    describe ".active" do
      before(:each) do
        VCR.insert_cassette('video_profile')
        @active_video_profile_version = Factory(:video_profile_version)
        @active_video_profile_version.pandize
        @active_video_profile_version.activate
        @experimental_video_profile = Factory(:video_profile)
      end
      
      it "should return all the active profiles" do
        VideoProfile.active.should == [@active_video_profile_version.profile]
      end
      
      after(:each) { VCR.eject_cassette }
    end
  end
  
  describe "Instance Methods" do
    before(:each) do
      VCR.insert_cassette('video_profile')
      @video_profile                = Factory(:video_profile)
      @active_video_profile_version = Factory(:video_profile_version, :profile => @video_profile)
      @active_video_profile_version.pandize
      @active_video_profile_version.activate
    end
    
    describe "#experimental_version" do
      it "should return the active version of a profile it's the latest version" do
        @video_profile.experimental_version.should == @active_video_profile_version
      end
      
      it "should return the last version of a profile (even if not active)" do
        @experimental_profile_version = Factory(:video_profile_version, :profile => @video_profile)
        @experimental_profile_version.pandize
        @video_profile.experimental_version.should == @experimental_profile_version
      end
    end
    
    describe "#active_version" do
      it "should return the last version of a profile (even if not active)" do
        @video_profile.active_version.should == @active_video_profile_version
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
end