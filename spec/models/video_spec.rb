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
  let(:encoding_id) { 'ab6be8bb1bcf506842264304bc1bb479' }
  
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
    
    # ===========
    # = pandize =
    # ===========
    describe "event(:pandize) { transition :pending => :encodings }" do
      let(:video) { Factory(:video) }
      
      it "should set the state as :encodings from :pending" do
        video.should be_pending
        VCR.use_cassette('video/pandize') { video.pandize }
        video.should be_encodings
      end
      
      describe "callbacks" do
        it "before_transition => #populate_information should set video information fetched from Panda" do
          video.stub!(:create_encodings => true)
          VCR.use_cassette('video/pandize') { video.pandize }
          video.original_filename.should be_present
          video.video_codec.should       be_present
          video.audio_codec.should       be_present
          video.extname.should           be_present
          video.file_size.should         be_present
          video.duration.should          be_present
          video.width.should             be_present
          video.height.should            be_present
          video.fps.should               be_present
        end
        
        it "after_transition => #create_encodings should create as many encodings as the number of current active profiles and delay pandize for each encoding" do
          video.stub!(:populate_information => true)
          2.times { Factory(:video_profile_version, :state => 'active') }
          VCR.use_cassette('video/pandize') { video.pandize }
          video.encodings.size.should == 2
          Delayed::Job.first.name.should == 'VideoEncoding#pandize'
          Delayed::Job.last.name.should == 'VideoEncoding#pandize'
        end
      end
    end
    
    # ===========
    # = suspend =
    # ===========
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
        let(:video) { Factory(:video, :state => 'encodings') }
        let(:video_encoding1) { Factory(:video_encoding, :video => video, :state => 'encoding') }
        let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'active') }
        
        it "before_transition => #suspend_encodings should suspend all the active encodings" do
          video_encoding1.should be_encoding
          video_encoding2.should be_active
          VCR.use_cassette('video/suspend') { video.suspend }
          video_encoding1.reload.should be_encoding
          video_encoding2.reload.should be_suspended
        end
      end
    end
    
    # =============
    # = unsuspend =
    # =============
    describe "event(:unsuspend) { transition :suspended => :encodings }" do
      let(:video) { Factory(:video, :state => 'suspended') }
      
      it "should set the state as :encodings from :suspended" do
        video.should be_suspended
        video.unsuspend
        video.should be_encodings
      end
      
      describe "callbacks" do
        let(:video_encoding1) { Factory(:video_encoding, :video => video, :state => 'encoding') }
        let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'suspended') }
        
        it "before_transition => #unsuspend_encodings should unsuspend all the suspended encodings" do
          video_encoding1.should be_encoding
          video_encoding2.should be_suspended
          video.unsuspend
          video_encoding1.reload.should be_encoding
          video_encoding2.reload.should be_active
        end
      end
    end
    
    # ===========
    # = archive =
    # ===========
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
        
        it "before_transition => #archive_encodings should delay the archive of every pending video encoding" do
          video.stub!(:set_archived_at => true, :remove_video_and_thumbnail! => true)
          active_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'pending')
          active_video_encoding.should be_pending
          
          video.archive
          VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
          
          active_video_encoding.reload.should be_archived
        end
        
        it "before_transition => #archive_encodings should delay the archive of every active video encoding" do
          video.stub!(:set_archived_at => true, :remove_video_and_thumbnail! => true)
          active_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'encoding')
          VCR.use_cassette('video_encoding/activate') { active_video_encoding.activate }
          active_video_encoding.should be_active
          active_video_encoding.file.should be_present
          
          video.archive
          VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
          
          active_video_encoding.reload.should be_archived
          active_video_encoding.file.should_not be_present
        end
        
        it "before_transition => #archive_encodings should delay the archive of every suspended video encoding" do
          video.stub!(:set_archived_at => true, :remove_video_and_thumbnail! => true)
          suspended_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'encoding')
          VCR.use_cassette('video_encoding/activate') { suspended_video_encoding.activate }
          VCR.use_cassette('video_encoding/suspend') { suspended_video_encoding.suspend }
          suspended_video_encoding.should be_suspended
          suspended_video_encoding.file.should be_present
          
          video.archive
          VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
          
          suspended_video_encoding.reload.should be_archived
          suspended_video_encoding.file.should_not be_present
        end
        
        it "before_transition => #archive_encodings should delay the archive of every encoding video encoding" do
          video.stub!(:set_archived_at => true, :remove_video_and_thumbnail! => true)
          encoding_video_encoding  = Factory(:video_encoding, :video => video)
          VCR.use_cassette('video_encoding/pandize') { encoding_video_encoding.pandize }
          encoding_video_encoding.should be_encoding
          encoding_video_encoding.file.should_not be_present
          
          video.archive
          VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
          
          encoding_video_encoding.reload.should be_archived
          encoding_video_encoding.file.should_not be_present
        end
        
        it "after_transition => #remove_video_and_thumbnail! should delay the DELETE request to Panda remove the original video file" do
          video.stub!(:set_archived_at => true, :archive_encodings => true)
          video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'encoding')
          video_encoding.profile.stub!(:thumbnailable? => true)
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video.thumbnail.should be_present
          video.archive
          Delayed::Job.last.name.should == 'Module#delete'
          video.thumbnail.should_not be_present
        end
      end
    end
    
  end
  
  describe "life cycle" do
    before(:each) do
      vpv1 = Factory(:video_profile_version, :profile => Factory(:video_profile, :thumbnailable => true))
      vpv2 = Factory(:video_profile_version)
      VCR.use_cassette('video_profile_version/pandize') do
        vpv1.pandize
        vpv2.pandize
      end
      vpv1.activate
      vpv2.activate
    end
    
    let(:video) { Factory(:video, :panda_video_id => 'a'*32) }
    
    it "should be consistent" do
      video.should be_pending
      VCR.use_cassette('video/pandize') { video.pandize }
      video.should be_encodings
      video.original_filename.should be_present
      video.video_codec.should       be_present
      video.audio_codec.should       be_present
      video.extname.should           be_present
      video.file_size.should         be_present
      video.duration.should          be_present
      video.width.should             be_present
      video.height.should            be_present
      video.fps.should               be_present
      VCR.use_cassette('video_encoding/pandize') { Delayed::Worker.new(:quiet => true).work_off }
      video.encodings[0].should be_encoding
      video.encodings[1].should be_encoding
      
      video.encodings[0].fail
      video.encodings[0].should be_failed
      video.should be_encodings
      video.should be_encoding
      video.should be_error
      video.should_not be_active
      
      VCR.use_cassette('video_encoding/pandize') { video.encodings[0].pandize }
      video.encodings[0].should be_encoding
      video.should be_encodings
      video.should be_encoding
      video.should_not be_error
      video.should_not be_active
      
      VCR.use_cassette('video_encoding/activate') { video.encodings[0].activate }
      video.encodings[0].should be_active
      video.should be_encodings
      video.should be_encoding
      video.should_not be_error
      video.should_not be_active
      video.reload.thumbnail.should be_present
      
      VCR.use_cassette('video_encoding/activate') { video.encodings[1].activate }
      video.encodings[1].should be_active
      video.should be_encodings
      video.should_not be_encoding
      video.should_not be_error
      video.should be_active
      
      VCR.use_cassette('video/suspend') { video.suspend }
      video.should be_suspended
      video.reload.encodings[0].should be_suspended
      video.encodings[1].should be_suspended
      
      video.unsuspend
      video.reload.should be_active
      video.encodings[0].should be_active
      video.encodings[1].should be_active
      
      VCR.use_cassette('video/archive') { video.archive }
      video.should be_archived
      VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
      video.encodings[0].reload.should be_archived
      video.encodings[1].reload.should be_archived
      video.thumbnail.should_not be_present
    end
  end
  
  describe "Instance Methods" do
    let(:video) { Factory(:video, :original_filename => 'hey_ho.mp4', :extname => '.mp4', :file_size => 1000) }
    
    describe "#name" do
      it "should return name used in the filename of the Video file" do
        video.original_filename.should == 'hey_ho.mp4'
        video.extname.should == '.mp4'
        video.name.should == 'hey_ho'
      end
    end
    
    describe "#total_size" do
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :state => 'encoding', :file_size => 42) }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'active', :file_size => 38) }
      
      it "should return total storage (reference video size + encoding sizes) only for active encodings" do
        video.file_size.should == 1000
        video_encoding1.file_size.should == 42
        video_encoding2.file_size.should == 38
        video.total_size.should == 1038
      end
    end
    
    describe "delegated states" do
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'encoding') }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'active') }
      
      describe "#encoding?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_encoding
        end
        
        it "should return false if video is in the encodings state and has no encoding encoding" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.update_attribute(:state, 'suspended')
          video.should_not be_encoding
        end
        
        it "should return true if any video encoding of a video is currently encoding" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.should be_encoding
          video.should be_encoding
        end
      end
      
      describe "#active?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_active
        end
        
        it "should return false if video is in the encodings state and has not all encoding active" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.should be_encoding
          video_encoding2.should be_active
          video.should_not be_active
        end
        
        it "should return true if all the encodings of a video are active" do
          video.update_attribute(:state, 'encodings')
          VCR.use_cassette('video_encoding/activate') { video_encoding1.activate }
          video_encoding1.should be_active
          video_encoding2.should be_active
          video.should be_active
        end
      end
      
      describe "#error?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_error
        end
        
        it "should return false if video is in the encodings state and has no encoding failed" do
          video.update_attribute(:state, 'encodings')
          video.should_not be_error
        end
        
        it "should return true if any video encoding of a video is currently failed" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.fail
          video_encoding1.should be_failed
          video.should be_error
        end
      end
    end
    
    describe "#hd?" do
      it "should return true if width >= 720" do
        video.update_attribute(:width, 720)
        video.should be_hd
      end
      
      it "should return true if height >= 1280" do
        video.update_attribute(:height, 1280)
        video.should be_hd
      end
      
      it "should return false if width < 720 and height < 1280" do
        video.update_attributes(:width => 719, :height => 1279)
        video.should_not be_hd
      end
    end
    
  end
  
end