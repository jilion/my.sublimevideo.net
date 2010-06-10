# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  panda_id    :string(255)
#  name        :string(255)
#  token       :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  codec       :string(255)
#  container   :string(255)
#  size        :integer
#  duration    :integer
#  width       :integer
#  height      :integer
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe Video do
  
  describe "base instance behaviour" do
    describe "Validations" do
      it "should validate presence of :user" do
        video = Factory.build(:video, :user => nil)
        video.should_not be_valid
        video.errors[:user].should be_present
      end
      
      it "should validate presence of :panda_video_id" do
        video = Factory.build(:video, :panda_video_id => nil)
        video.should_not be_valid
        video.errors[:panda_video_id].should be_present
      end
    end
  end
  
  describe "Class Methods" do
  end
  
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
      before(:each) do
        @active_video_profile1 = Factory(:video_profile, :active_version => Factory(:video_profile_version))
        @active_video_profile2 = Factory(:video_profile, :active_version => Factory(:video_profile_version))
        Factory(:video_profile) # non-active profile
        @video = Factory(:video)
        VCR.use_cassette('video') { @video.pandize }
        @video.should be_valid
      end
      
      it "should set the state as :encodings" do
        @video.should be_encodings
      end
      
      describe "before_transition => #set_video_information" do
        it "should set video informations fetched from the transcoder service" do
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
        it "should create as many encodings as the number of current active profiles" do
          @video.encodings.size.should == 2
          @video.encodings[0].profile.should == @active_video_profile1
          @video.encodings[1].profile.should == @active_video_profile2
        end
      end
    end
    
    describe "event(:suspend)" do
      context "on a pending video" do
        before(:each) do
          @video = Factory(:video)
          VCR.use_cassette('video') { @video.suspend }
          @video.should be_valid
        end
        
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
        before(:each) do
          VCR.insert_cassette('video')
          Factory(:video_profile, :active_version => Factory(:video_profile_version))
          @video = Factory(:video)
          @video.pandize
          @video.should be_valid
        end
        
        it "should set the state as :encodings" do
          @video.suspend
          @video.should be_encodings
        end
        
        describe "before_transition => #block_video" do
          it "should set the READ right to NOBODY (or OWNER if it's enough)" do
            
          end
        end
        
        describe "after_transition => #purge_video_and_thumbnail_file" do
          it "should purge every encodings file from the cdn and the thumbnail" do
            @video.encodings.each do |e|
              CDN.should_receive(:purge).with("/v/#{@video.token}/#{@video.name}#{e.profile.name}#{e.extname}")
            end
            CDN.should_receive(:purge).with("/v/#{@video.token}/#{@video.name}.jpg")
            @video.suspend
          end
        end
        
        after(:each) { VCR.eject_cassette }
      end
    end
    
    describe "event(:unsuspend)" do
      before(:each) do
        VCR.insert_cassette('video')
        Factory(:video_profile, :active_version => Factory(:video_profile_version))
        @video = Factory(:video)
        @video.pandize
        @video.unsuspend
        @video.should be_valid
      end
      
      it "should set the state as :encodings" do
        @video.should be_encodings
      end
      
      describe "before_transition => #unblock_video" do
        it "should set the READ right to WORLD" do
          
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "event(:archive)" do
      context "on a pending video" do
        before(:each) do
          VCR.insert_cassette('video')
          Factory(:video_profile, :active_version => Factory(:video_profile_version))
          @video = Factory(:video)
          @video.archive
          @video.should be_valid
        end
        
        it "should set the state as :archived" do
          @video.should be_archived
        end
        
        describe "before_transition => #set_archived_at" do
          it "should set archived_at to now, the video is not accessible anymore, anywhere, anytime, THE END!" do
            @video.archived_at.should be_present
          end
        end
        
        describe "before_transition => #archive_encodings" do
          it "should not archive any encodings since the video is pending!" do
            @video.encodings.should be_empty
          end
        end
        
        describe "after_transition => #remove_video_and_thumbnail_file!" do
          it "should not remove any file since the video is pending" do
            @video.thumbnail.should_not be_present
          end
        end
        
        after(:each) { VCR.eject_cassette }
      end
      
      context "on a encodings video" do
        before(:each) do
          VCR.insert_cassette('video')
          Factory(:video_profile, :active_version => Factory(:video_profile_version))
          @video = Factory(:video)
          @video.pandize
          @video.archive
          @video.should be_valid
        end
        
        it "should set the state as :archived" do
          @video.should be_archived
        end
        
        describe "before_transition => #set_archived_at" do
          it "should set archived_at to now, the video is not accessible anymore, anywhere, anytime, THE END!" do
            @video.archived_at.should be_present
          end
        end
        
        describe "before_transition => #archive_encodings" do
          it "should archive every encodings!" do
            @video.encodings.each { |e| e.should be_archived }
          end
        end
        
        describe "after_transition => #remove_video_and_thumbnail_file!" do
          it "should remove the original video file, all the video encodings files and the thumbnail from the storage" do
            @video.thumbnail.should_not be_present
          end
        end
        
        after(:each) { VCR.eject_cassette }
      end
    end
    
  end
  
  describe "Instance Methods" do
    before(:each) do
      VCR.insert_cassette('video')
      Factory(:video_profile, :active_version => Factory(:video_profile_version))
      @video = Factory(:video)
      @video.pandize
      @video.should be_valid
    end
    
    describe "#name" do
      it "should return name used in the filename of the VideoEncoding files" do
        @video.name.should == @video.original_filename.sub(@video.extname, '')
      end
    end
    
    describe "#total_size" do
      it "should return total storage (reference video size + encoding sizes)" do
        @video.total_size.should == @video.file_size + @video.encodings.sum(:file_size)
      end
    end
    
    describe "#active" do
      it "should return true if all the encodings of a video are active" do
        @video.should_not be_active
        
        @video.encodings.each do |e|
          e.activate
          e.reload
          e.should be_active
        end
        @video.should be_active
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
end

def fake_post_video
  Transcoder.post(:video, :file => "#{Rails.root}/spec/fixtures/railscast_intro.mov")
end