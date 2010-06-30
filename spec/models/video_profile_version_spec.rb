# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  state            :string(255)
#  note             :text
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe VideoProfileVersion do
  let(:id) { 'f703bb7c207c472ceefd9c0d3986bf54' }
  
  context "with valid attributes" do
    subject { Factory(:video_profile_version) }
    
    its(:profile)          { should be_present                   }
    its(:panda_profile_id) { should be_nil                       }
    its(:width)            { should == 480                       }
    its(:height)           { should == 640                       }
    its(:command)          { should == 'Handbrake CLI blabla...' }
    
    it { should be_valid }
  end
  
  describe "accessible attributes" do
    subject { VideoProfileVersion.new(:width => 640, :height => 480, :command => "Handbrake CLI", :profile => Factory(:video_profile)) }
    
    its(:profile)          { should be_present }
    its(:width)            { should be_present }
    its(:height)           { should be_present }
    its(:command)          { should be_present }
    
    it { should be_valid }
  end
  
  describe "Scopes" do
    describe "active" do
      let(:active_video_profile) { Factory(:video_profile) }
      let(:active_video_profile_version) { Factory(:video_profile_version, :state => 'active', :profile => active_video_profile) }
      
      it "should return video profile version that have the :active state" do
        VideoProfileVersion.active.should == [active_video_profile_version]
      end
    end
    
    describe "dimensions_less_than" do
      before(:each) do
        sd_profile = Factory(:video_profile, :min_width => 0, :min_height => 0) # SD
        hq_profile = Factory(:video_profile, :min_width => 854, :min_height => 480) # HQ
        hd_profile = Factory(:video_profile, :min_width => 1280, :min_height => 720) # HD
        @sd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => sd_profile)
        @hq_profile_version = Factory(:video_profile_version, :state => 'active', :profile => hq_profile)
        @hd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => hd_profile)
      end
      
      # MP4 Input file example  SD minW:0 minH:0  HQ minW:854 minH:480  HD minW:1280 minH:720
      # 1)  320x240             320x240           -                     -
      # 2)  480x270             480x270           -                     -
      # 3)  640x360             640x360           -                     -
      # 4)  640x480             480x360           640x480               -
      # 5)  848x480             636x360           848x480               -
      # 6)  864x540             576x360           768x480               -
      # 7)  1280x544            640x272           854x363               1280x544
      # 8)  1280x720            640x360           854x480               1280x720
      # 9)  720x1280 (iPhone4)  202x360           270x480               405x720
      # 10) 1920x1080           640x360           854x480               1280x720
      
      [[320,240], [480,270], [640,360]].each do |size|
        it "should return video profiles version that have their profile with #{size[0]} >= min_width and #{size[1]} >= min_height: SD" do
          VideoProfileVersion.dimensions_less_than(size[0], size[1]).order(:created_at).should == [@sd_profile_version]
        end
      end
      
      [[640,480], [848,480], [768,480]].each do |size|
        it "should return video profiles version that have their profile with #{size[0]} >= min_width and #{size[1]} >= min_height: HQ" do
          VideoProfileVersion.dimensions_less_than(size[0], size[1]).order(:created_at).should == [@sd_profile_version, @hq_profile_version]
        end
      end
      
      [[1280,544], [1280,720], [720,1280], [1920,1080]].each do |size|
        it "should return video profiles version that have their profile with #{size[0]} >= min_width and #{size[1]} >= min_height: HD" do
          VideoProfileVersion.dimensions_less_than(size[0], size[1]).order(:created_at).should == [@sd_profile_version, @hq_profile_version, @hd_profile_version]
        end
      end
    end
    
    describe "use_webm" do
      before(:each) do
        mp4_profile = Factory(:video_profile, :extname => 'mp4') # SD
        webm_profile = Factory(:video_profile, :extname => 'webm') # SD
        @mp4_profile_version = Factory(:video_profile_version, :state => 'active', :profile => mp4_profile)
        @webm_profile_version = Factory(:video_profile_version, :state => 'active', :profile => webm_profile)
      end
      
      it "should return only video profile versions that are not webm if false is given" do
        VideoProfileVersion.use_webm(false).should == [@mp4_profile_version]
      end
      
      it "should return video profile versions including webm ones if true is given" do
        VideoProfileVersion.use_webm(true).should == [@mp4_profile_version, @webm_profile_version]
      end
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
    describe "initial state" do
      subject { Factory(:video_profile_version) }
      it { should be_pending }
    end
    
    describe "event(:pandize)" do
      before(:each) { VCR.insert_cassette('video_profile_version/pandize') }
      
      let(:video_profile) { Factory(:video_profile) }
      
      it "should set the state as :experimental from :pending" do
        video_profile_version = Factory(:video_profile_version, :profile => video_profile)
        video_profile_version.should be_pending
        video_profile_version.pandize
        video_profile_version.should be_experimental
      end
      
      describe "callbacks" do
        let(:video_profile_version) { Factory(:video_profile_version, :profile => video_profile) }
        let(:params) { { :title => "#{video_profile.title} #1", :extname => ".#{video_profile.extname}", :width => video_profile_version.width, :height => video_profile_version.height, :command => video_profile_version.command } }
        
        describe "before_transition :on => :pandize, :do => :create_panda_profile_and_set_info" do
          it "should send a post request to Panda" do
            Transcoder.should_receive(:post).with(:profile, params).and_return({})
            video_profile_version.pandize
          end
          
          it "should set profile info" do
            video_profile_version.pandize
            video_profile_version.panda_profile_id.should == id
            video_profile_version.should be_experimental
          end
          
          it "should send us a notification via Hoptoad if creation has failed on Panda" do
            Transcoder.should_receive(:post).with(:profile, params).and_return({ :error => "BadRequest", :message => "Error" })
            HoptoadNotifier.should_receive(:notify).with("VideoProfileVersion (#{video_profile_version.id}) panda profile creation error: Error")
            video_profile_version.pandize
            video_profile_version.should be_pending
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "event(:activate)" do
      before(:each) { VCR.insert_cassette('video_profile_version/activate') }
      
      let(:video_profile) { Factory(:video_profile) }
      let(:video_profile_version) { Factory(:video_profile_version, :state => 'experimental', :profile => video_profile, :panda_profile_id => id) }
      
      it "should set the state as :active from :experimental" do
        video_profile_version.should be_experimental
        video_profile_version.activate
        video_profile_version.should be_active
      end
      
      describe "callbacks" do
        describe "after_transition :on => :activate, :do => :deprecate_profile_versions" do
          it "should deprecate all the active profile version for the same profile" do
            active_video_profile_version = Factory(:video_profile_version, :state => 'active', :profile => video_profile)
            video_profile_version.pandize
            video_profile_version.activate
            video_profile_version.should be_active
            active_video_profile_version.reload.should be_deprecated
          end
          
          it "should deprecate all the experimental profile version for the same profile" do
            experimental_video_profile_version = Factory(:video_profile_version, :state => 'experimental', :profile => video_profile, :panda_profile_id => id)
            video_profile_version.activate
            video_profile_version.should be_active
            experimental_video_profile_version.reload.should be_deprecated
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
  describe "Instance Methods" do
    
    describe "#rank" do
      let(:video_profile) { Factory(:video_profile) }
      let(:video_profile_version1) { Factory(:video_profile_version, :state => 'experimental', :profile => video_profile, :panda_profile_id => id) }
      let(:video_profile_version2) { Factory(:video_profile_version, :state => 'experimental', :profile => video_profile, :panda_profile_id => id) }
      
      it "should return the rank of this version among all its versions" do
        video_profile_version1.should be_experimental
        video_profile_version2.should be_experimental
        video_profile.versions.reload.size.should == 2
        video_profile.versions.order(:created_at.asc).first.should == video_profile_version1
        video_profile.versions.order(:created_at.asc).last.should == video_profile_version2
        video_profile_version1.rank.should == 1
        video_profile_version2.rank.should == 2
      end
      
    end
    
  end
  
end