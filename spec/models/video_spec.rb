# == Schema Information
#
# Table name: videos
#
#  id                :integer         not null, primary key
#  user_id           :integer
#  title             :string(255)
#  token             :string(255)
#  state             :string(255)
#  thumbnail         :string(255)
#  hits_cache        :integer         default(0)
#  bandwidth_cache   :integer         default(0)
#  panda_video_id    :string(255)
#  original_filename :string(255)
#  video_codec       :string(255)
#  audio_codec       :string(255)
#  extname           :string(255)
#  file_size         :integer
#  duration          :integer
#  width             :integer
#  height            :integer
#  fps               :integer
#  archived_at       :datetime
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe Video do
  
  context "with valid attributes" do
    subject { Factory(:video) }
    
    its(:user)              { should be_present       }
    its(:panda_video_id)    { should be_present       }
    its(:title)             { should be_nil           }
    its(:token)             { should =~ /[a-z0-9]{8}/ }
    its(:hits_cache)        { should == 0             }
    its(:bandwidth_cache)   { should == 0             }
    its(:original_filename) { should be_nil           }
    its(:video_codec)       { should be_nil           }
    its(:audio_codec)       { should be_nil           }
    its(:extname)           { should be_nil           }
    its(:file_size)         { should be_nil           }
    its(:duration)          { should be_nil           }
    its(:width)             { should be_nil           }
    its(:height)            { should be_nil           }
    its(:fps)               { should be_nil           }
    its(:archived_at)       { should be_nil           }
    
    it { should be_valid   }
  end
  
  describe "Validations" do
    it "should validate presence of :user" do
      video = Factory.build(:video, :user => nil)
      video.should_not be_valid
      video.should have(1).error_on(:user)
    end
    it "should validate presence of :panda_video_id" do
      video = Factory.build(:video, :panda_video_id => nil)
      video.should_not be_valid
      video.should have(1).error_on(:panda_video_id)
    end
  end
  
  describe "State Machine" do
    
    describe "initial state" do
      subject { Factory(:video) }
      it { should be_pending }
    end
    
    describe "event(:pandize) { transition :pending => :encodings }" do
      before(:each) { @video = Factory(:video) }
      
      it "should set the state as :encodings from :pending" do
        @video.should be_pending
        VCR.use_cassette('video/pandize') { @video.pandize }
        @video.should be_encodings
      end
      
      describe "callbacks" do
        it "before_transition => #set_video_information should set video information fetched from Panda" do
          @video.stub!(:create_encodings => true)
          VCR.use_cassette('video/pandize') { @video.pandize }
          @video.original_filename.should be_present
          @video.video_codec.should       be_present
          @video.audio_codec.should       be_present
          @video.extname.should           be_present
          @video.file_size.should         be_present
          @video.duration.should          be_present
          @video.width.should             be_present
          @video.height.should            be_present
          @video.fps.should               be_present
        end
        
        it "after_transition => #create_encodings should create as many encodings as the number of current active profiles and delay pandize for each encoding" do
          @video.stub!(:set_video_information => true)
          2.times { Factory(:video_profile_version, :state => 'active') }
          VCR.use_cassette('video/pandize') { @video.pandize }
          @video.encodings.size.should == 2
          Delayed::Job.first.name.should == 'VideoEncoding#pandize'
          Delayed::Job.last.name.should == 'VideoEncoding#pandize'
        end
      end
    end
    
    describe "event(:suspend) { transition [:pending, :encodings] => :suspended }" do
      it "should set the state as :suspended from :pending" do
        video = Factory(:video, :state => 'pending')
        video.should be_pending
        VCR.use_cassette('video/suspend') { video.suspend }
        video.should be_suspended
      end
      
      it "should set the state as :suspended from :encodings" do
        video = Factory(:video, :state => 'encodings')
        video.should be_encodings
        VCR.use_cassette('video/suspend') { video.suspend }
        video.should be_suspended
      end
      
      describe "callbacks" do
        before(:each) do
          @video = Factory(:video, :state => 'encodings')
          Factory(:video_encoding, :video => @video, :state => 'encoding')
          Factory(:video_encoding, :video => @video, :state => 'active')
        end
        
        it "before_transition => #suspend_encodings should suspend all the active encodings" do
          @video.encodings[0].should be_encoding
          @video.encodings[1].should be_active
          VCR.use_cassette('video/suspend') { @video.suspend }
          @video.encodings[0].reload.should be_encoding
          @video.encodings[1].reload.should be_suspended
        end
      end
    end
    
    describe "event(:unsuspend) { transition :suspended => :encodings }" do
      before(:each) do
        @video = Factory(:video, :state => 'suspended')
        Factory(:video_encoding, :video => @video, :state => 'encoding')
        Factory(:video_encoding, :video => @video, :state => 'suspended')
      end
      
      it "should set the state as :encodings from :suspended" do
        @video.should be_suspended
        @video.unsuspend
        @video.should be_encodings
      end
      
      describe "callbacks" do
        it "before_transition => #unsuspend_encodings should unsuspend all the suspended encodings" do
          @video.encodings[0].should be_encoding
          @video.encodings[1].should be_suspended
          @video.unsuspend
          @video.encodings[0].reload.should be_encoding
          @video.encodings[1].reload.should be_active
        end
      end
    end
    
    describe "event(:archive) { transition [:pending, :encodings, :suspended] => :archived }" do
      it "should set the state as :archived from :pending" do
        video = Factory(:video, :state => 'pending')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video_and_thumbnail! => true)
        video.should be_pending
        VCR.use_cassette('video/archive') { video.archive }
        video.should be_archived
      end
      
      it "should set the state as :archived from :encodings" do
        video = Factory(:video, :state => 'encodings')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video_and_thumbnail! => true)
        video.should be_encodings
        VCR.use_cassette('video/archive') { video.archive }
        video.should be_archived
      end
      
      it "should set the state as :archived from :suspended" do
        video = Factory(:video, :state => 'suspended')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video_and_thumbnail! => true)
        video.should be_suspended
        VCR.use_cassette('video/archive') { video.archive }
        video.should be_archived
      end
      
      describe "callbacks" do
        let(:video) { Factory(:video, :state => 'encodings') }
        
        it "before_transition => #set_archived_at should set archived_at to now" do
          video.stub!(:archive_encodings => true, :remove_video_and_thumbnail! => true)
          video.archive
          video.archived_at.should be_present
        end
        
        it "before_transition => #archive_encodings should delay the archive of every active encoding" do
          Factory(:video_encoding, :video => video, :state => 'encoding')
          Factory(:video_encoding, :video => video, :state => 'active')
          video.stub!(:set_archived_at => true, :remove_video_and_thumbnail! => true)
          video.archive
          Delayed::Job.first.name.should == 'VideoEncoding#archive'
          Delayed::Job.last.name.should == 'VideoEncoding#archive'
        end
        
        it "after_transition => #remove_video_and_thumbnail! should delay the DELETE request to Panda remove the original video file" do
          video.stub!(:set_archived_at => true, :archive_encodings => true)
          video_encoding = Factory(:video_encoding, :video => video, :state => 'encoding', :panda_encoding_id => 'a'*32)
          video_encoding.profile.stub!(:thumbnailable? => true)
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video.thumbnail.should be_present
          VCR.use_cassette('video/archive') { video.archive }
          Delayed::Job.last.name.should == 'Module#delete'
          video.thumbnail.should_not be_present
        end
      end
      
    end
    
  end
  
  describe "Instance Methods" do
    before(:each) { @video = Factory(:video) }
    
    describe "#name" do
      it "should return name used in the filename of the Video file" do
        VCR.use_cassette('video/pandize') { @video.pandize }
        @video.name.should == @video.original_filename.sub(@video.extname, '')
      end
    end
    
    describe "#total_size" do
      it "should return total storage (reference video size + encoding sizes)" do
        2.times do
          vpv = Factory(:video_profile_version)
          VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
          vpv.activate
        end
        VCR.use_cassette('video/pandize') { @video.pandize }
        
        @video.encodings[0].update_attribute(:file_size, 10)
        @video.encodings[1].update_attribute(:file_size, 20)
        @video.total_size.should == @video.file_size + 10 + 20
      end
    end
    
    describe "#encoding?" do
      it "should return true if any video encoding of a video is currently encoding" do
        2.times do
          vpv = Factory(:video_profile_version)
          VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
          vpv.activate
        end
        VCR.use_cassette('video/pandize') do
          @video.pandize
          Delayed::Worker.new(:quiet => true).work_off
        end
        
        @video.should be_encoding
        @video.encodings.each do |e|
          VCR.use_cassette('video_encoding/activate') { e.activate }
          e.should be_active
        end
        @video.should_not be_encoding
      end
    end
    
    describe "#active?" do
      it "should return false if video has no encodings" do
        VCR.use_cassette('video/pandize') { @video.pandize }
        
        @video.encodings.should be_empty
        @video.should_not be_active
      end
      
      it "should return true if all the encodings of a video are active" do
        2.times do
          vpv = Factory(:video_profile_version)
          VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
          vpv.activate
        end
        VCR.use_cassette('video/pandize') do
          @video.pandize
          Delayed::Worker.new(:quiet => true).work_off
        end
        
        @video.should_not be_active
        @video.encodings.each do |e|
          VCR.use_cassette('video_encoding/activate') { e.activate }
          e.should be_active
        end
        @video.should be_active
      end
    end
    
    describe "#failed?" do
      it "should return true if any video encoding of a video is currently failed" do
        vpv = Factory(:video_profile_version)
        VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
        vpv.activate
        VCR.use_cassette('video/pandize') do
          @video.pandize
          Delayed::Worker.new(:quiet => true).work_off
        end
        
        @video.should_not be_failed
        @video.encodings.first.fail
        @video.encodings.first.should be_failed
        @video.should be_failed
      end
    end
    
    describe "#hd?" do
      it "should return true if width >= 720" do
        @video.update_attribute(:width, 720)
        @video.should be_hd
      end
      
      it "should return true if height >= 1280" do
        @video.update_attribute(:height, 1280)
        @video.should be_hd
      end
      
      it "should return false if width < 720 and height < 1280" do
        @video.update_attributes(:width => 719, :height => 1279)
        @video.should_not be_hd
      end
    end
    
  end
  
end