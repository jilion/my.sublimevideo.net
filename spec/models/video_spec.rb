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
      video.should have(1).errors_on(:user)
    end
    it "should validate presence of :panda_video_id" do
      video = Factory.build(:video, :panda_video_id => nil)
      video.should_not be_valid
      video.should have(1).errors_on(:panda_video_id)
    end
  end
  
  describe "State Machine" do
    
    describe "initial state" do
      subject { Factory(:video) }
      it { should be_pending }
    end
    
    describe "event(:pandize)" do
      before(:each) { @video = Factory(:video) }
      
      context "panda_video_id is not nil" do
        it "should set the state as :encodings" do
          VCR.use_cassette('video/pandize') { @video.pandize }
          @video.should be_encodings
        end
        
        it "should delay pandize for each encodings" do
          vpv = Factory(:video_profile_version)
          VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
          vpv.activate
          VCR.use_cassette('video/pandize') do
            @video.pandize
            Delayed::Job.last.name.should == 'VideoEncoding#pandize'
            Delayed::Worker.new.work_off
          end
        end
        
        describe "before_transition => #set_video_information" do
          it "should set video informations fetched from the transcoder service" do
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
        end
        
        describe "after_transition => #create_encodings" do
          before(:each) do
          end
          
          it "should create as many encodings as the number of current active profiles" do
            active_video_profile_versions = 2.times.inject([]) do |memo, i|
              vpv = Factory(:video_profile_version)
              VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
              vpv.activate
              memo << vpv
            end
            VCR.use_cassette('video/pandize') { @video.pandize }
            
            @video.encodings.size.should == 2
            @video.encodings[0].profile.should == active_video_profile_versions[0].profile
            @video.encodings[1].profile.should == active_video_profile_versions[1].profile
          end
        end
      end
    end
    
    describe "event(:suspend)" do
      before(:each) do
        @video = Factory(:video)
        active_video_profile_version = Factory(:video_profile_version)
        VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
        active_video_profile_version.activate
      end
      
      context "on a pending video" do
        before(:each) { VCR.use_cassette('video/suspend') { @video.suspend } }
        
        it "should set the state as :encodings" do
          @video.should be_encodings
        end
        
        describe "before_transition => #block_video" do
          it "should not try to change the rights since it has no encodings" do
            
          end
        end
        
        describe "after_transition => #purge_video_and_thumbnail_file" do
          it "should not call purge since it has no encodings" do
            CDN.should_not_receive(:purge)
          end
        end
      end
      
      context "on a encodings video" do
        before(:each) { VCR.use_cassette('video/pandize') { @video.pandize } }
        
        it "should set the state as :encodings" do
          VCR.use_cassette('video/suspend') { @video.suspend }
          @video.should be_encodings
        end
        
        pending "before_transition => #block_video" do
          it "should set the READ right to NOBODY (or OWNER if it's enough)" do
            
          end
        end
        
        describe "after_transition => #purge_video_and_thumbnail_file" do
          it "should purge every encodings file from the cdn and the thumbnail" do
            @video.encodings.each do |e|
              CDN.should_receive(:purge).with("/v/#{@video.token}/#{@video.name}#{e.profile.name}#{e.extname}")
            end
            CDN.should_receive(:purge).with("/v/#{@video.token}/posterframe.jpg")
            VCR.use_cassette('video/suspend') { @video.suspend }
          end
        end
      end
      
    end
    
    describe "event(:unsuspend)" do
      before(:each) do
        @video = Factory(:video, :state => 'encodings')
        @video.unsuspend
      end
      
      it "should set the state as :encodings" do
        @video.should be_encodings
      end
      
      pending "before_transition => #unblock_video" do
        it "should set the READ right to WORLD" do
          
        end
      end
    end
    
    describe "event(:archive)" do
      before(:each) do
        active_video_profile_version = Factory(:video_profile_version)
        VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
        active_video_profile_version.activate
      end
      
      context "on a pending video" do
        before(:each) { @video = Factory(:video) }
        
        describe "before_transition => #set_archived_at" do
          it "should set archived_at to now, the video is not accessible anymore, anywhere, anytime, THE END!" do
            @video.stub!(:archive_encodings => true, :remove_video_and_thumbnail_file => true)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.archived_at.should be_present
            @video.should be_archived
          end
        end
        
        describe "before_transition => #archive_encodings" do
          it "should not archive any encodings since the video is pending!" do
            @video.stub!(:set_archived_at => true, :remove_video_and_thumbnail_file => true)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.encodings.should be_empty
            @video.should be_archived
          end
        end
        
        describe "after_transition => #remove_video_and_thumbnail_file!" do
          it "should not remove any file since the video is pending" do
            @video.stub!(:set_archived_at => true, :archive_encodings => true)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.thumbnail.should_not be_present
            @video.should be_archived
          end
        end
      end
      
      context "on a encodings video" do
        before(:each) { @video = Factory(:video, :state => 'encodings') }
        
        describe "before_transition => #set_archived_at" do
          it "should set archived_at to now, the video is not accessible anymore, anywhere, anytime, THE END!" do
            @video.stub!(:archive_encodings => true, :remove_video_and_thumbnail_file => true)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.archived_at.should be_present
            @video.should be_archived
          end
        end
        
        describe "before_transition => #archive_encodings" do
          it "should archive every encodings!" do
            @video.stub!(:set_archived_at => true, :remove_video_and_thumbnail_file => true)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.encodings.each { |e| e.should be_archived }
            @video.should be_archived
          end
        end
        
        describe "after_transition => #remove_video!" do
          it "should remove the original video file" do
            @video.stub!(:set_archived_at => true, :archive_encodings => true)
            Transcoder.should_receive(:delete).with(:video, @video.panda_video_id)
            VCR.use_cassette('video/archive') { @video.archive }
            @video.should be_archived
          end
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
    
    describe "#in_progress?" do
      it "should return true if any video encoding of a video is currently encoding" do
        2.times do
          vpv = Factory(:video_profile_version)
          VCR.use_cassette('video_profile_version/pandize') { vpv.pandize }
          vpv.activate
        end
        VCR.use_cassette('video/pandize') do
          @video.pandize
          Delayed::Worker.new.work_off
        end
        
        @video.should be_in_progress
        @video.encodings.each do |e|
          VCR.use_cassette('video_encoding/activate') { e.activate }
          e.should be_active
        end
        @video.should_not be_in_progress
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
          Delayed::Worker.new.work_off
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
          Delayed::Worker.new.work_off
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