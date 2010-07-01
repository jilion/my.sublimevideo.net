# == Schema Information
#
# Table name: video_profiles
#
#  id             :integer         not null, primary key
#  title          :string(255)
#  description    :text
#  name           :string(255)
#  extname        :string(255)
#  posterframeable  :boolean
#  min_width      :integer
#  min_height     :integer
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
    its(:min_width)   { should == 0       }
    its(:min_height)  { should == 0       }
    
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
    it "should validate uniqueness of [:name, :extname]" do
      video_profile = Factory.create(:video_profile, :name => '720p', :extname => 'mp4')
      video_profile2 = Factory.create(:video_profile, :name => '720i', :extname => 'mp4')
      video_profile3 = Factory.build(:video_profile, :name => '720p', :extname => 'mp4')
      video_profile3.should_not be_valid
      video_profile3.errors[:name].should be_present
    end
  end
  
  describe "Callbacks" do
    describe "before_create" do
      it "should set posterframeable to false if not specified" do
        vp = Factory(:video_profile)
        vp.should be_valid
        vp.posterframeable.should be_false
      end
      it "should not set posterframeable to false if specified" do
        vp = Factory(:video_profile, :posterframeable => true)
        vp.posterframeable.should be_true
      end
      it "should set min_width to 0 if not specified" do
        vp = Factory(:video_profile)
        vp.should be_valid
        vp.min_width.should == 0
      end
      it "should not set min_width to 0 if specified" do
        vp = Factory(:video_profile, :min_width => 600)
        vp.min_width.should == 600
      end
      it "should set min_height to 0 if not specified" do
        vp = Factory(:video_profile)
        vp.should be_valid
        vp.min_height.should == 0
      end
      it "should not set min_height to 0 if specified" do
        vp = Factory(:video_profile, :min_height => 300)
        vp.min_height.should == 300
      end
    end
  end
  
  describe "Instance Methods" do
    before(:each) do
      @video_profile                = Factory(:video_profile)
      @active_video_profile_version = Factory(:video_profile_version, :profile => @video_profile)
      VCR.use_cassette('video_profile_version/pandize') { @active_video_profile_version.pandize }
      VCR.use_cassette('video_profile_version/activate') { @active_video_profile_version.activate }
    end
    
    describe "#experimental_version" do
      it "should return the active version of a profile if it's the latest version" do
        @video_profile.experimental_version.should == @active_video_profile_version
      end
      
      it "should return the last version of a profile (even if not active)" do
        @experimental_profile_version = Factory(:video_profile_version, :profile => @video_profile)
        VCR.use_cassette('video_profile_version/pandize') { @experimental_profile_version.pandize }
        @video_profile.experimental_version.should == @experimental_profile_version
      end
    end
    
    describe "#active_version" do
      it "should return the last version of a profile (even if not active)" do
        @video_profile.active_version.should == @active_video_profile_version
      end
    end
  end
  
end
