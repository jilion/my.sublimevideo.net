# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  state            :string(255)
#  num              :integer
#  note             :text
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe VideoProfileVersion do
  
  context "with valid attributes" do
    before(:each) { VCR.insert_cassette('video_profile') }
    
    subject { Factory(:video_profile_version) }
    
    its(:profile)          { should be_present                   }
    its(:panda_profile_id) { should be_nil                       }
    its(:width)            { should == 480                       }
    its(:height)           { should == 640                       }
    its(:command)          { should == 'Handbrake CLI blabla...' }
    
    it { should be_valid }
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Scopes" do
    describe "active" do
      before(:each) do
        VCR.insert_cassette('video_profile')
        @active_video_profile = Factory(:video_profile)
        Factory(:video_profile_version, :profile => @active_video_profile)
        @active_video_profile_version = Factory(:video_profile_version, :profile => @active_video_profile)
        @active_video_profile_version.pandize
        @active_video_profile_version.activate
      end
      
      it "should return video profile version that have the :active state" do
        VideoProfileVersion.active.should == [@active_video_profile_version]
      end
      
      after(:each) { VCR.eject_cassette }
    end
  end
  
  describe "Validations" do
    it "should validate presence of :width" do
      video_profile = Factory.build(:video_profile_version, :width => nil)
      video_profile.should_not be_valid
      video_profile.errors[:width].should be_present
    end
    it "should validate presence of :height" do
      video_profile = Factory.build(:video_profile_version, :height => nil)
      video_profile.should_not be_valid
      video_profile.errors[:height].should be_present
    end
    it "should validate presence of :command" do
      video_profile = Factory.build(:video_profile_version, :command => nil)
      video_profile.should_not be_valid
      video_profile.errors[:command].should be_present
    end
  end
  
  describe "State Machine" do
    before(:each) { VCR.insert_cassette('video_profile') }
    
    describe "initial state" do
      subject { Factory(:video_profile_version) }
      
      it { should be_pending }
    end
    
    describe "event(:pandize)" do
      before(:each) do
        @active_video_profile         = Factory(:video_profile)
        @active_video_profile_version = Factory(:video_profile_version, :profile => @active_video_profile)
      end
      
      it "should set the state as :experimental" do
        @active_video_profile_version.pandize
        @active_video_profile_version.should be_experimental
      end
      
      describe "before_transition => #create_panda_profile" do
        it "should create the profile on Panda" do
          params = { :title => "#{@active_video_profile.title} #1", :extname => @active_video_profile.extname, :width => @active_video_profile_version.width, :height => @active_video_profile_version.height, :command => @active_video_profile_version.command }
          Transcoder.should_receive(:post).with(:profile, params).and_return({:id => 'a'*32})
          @active_video_profile_version.pandize
          @active_video_profile_version.panda_profile_id.should == 'a'*32
          @active_video_profile_version.should be_experimental
        end
        
        it "should add an error to base if the creation of the Panda profile has failed" do
          params = { :title => "#{@active_video_profile.title} #1", :extname => @active_video_profile.extname, :width => @active_video_profile_version.width, :height => @active_video_profile_version.height, :command => @active_video_profile_version.command }
          Transcoder.should_receive(:post).with(:profile, params).and_return({:error => "failed", :message => "Creation has failed"})
          @active_video_profile_version.pandize
          @active_video_profile_version.errors[:state].should == ["cannot transition via \"pandize\""]
          @active_video_profile_version.panda_profile_id.should be_nil
          @active_video_profile_version.should be_pending
        end
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
end