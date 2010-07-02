# == Schema Information
#
# Table name: videos
#
#  id                      :integer         not null, primary key
#  user_id                 :integer
#  title                   :string(255)
#  token                   :string(255)
#  state                   :string(255)
#  posterframe             :string(255)
#  hits_cache              :integer         default(0)
#  bandwidth_s3_cache      :integer         default(0)
#  bandwidth_us_cache      :integer         default(0)
#  bandwidth_eu_cache      :integer         default(0)
#  bandwidth_as_cache      :integer         default(0)
#  bandwidth_jp_cache      :integer         default(0)
#  bandwidth_unknown_cache :integer         default(0)
#  requests_s3_cache       :integer         default(0)
#  requests_us_cache       :integer         default(0)
#  requests_eu_cache       :integer         default(0)
#  requests_as_cache       :integer         default(0)
#  requests_jp_cache       :integer         default(0)
#  requests_unknown_cache  :integer         default(0)
#  panda_video_id          :string(255)
#  original_filename       :string(255)
#  video_codec             :string(255)
#  audio_codec             :string(255)
#  extname                 :string(255)
#  file_size               :integer
#  duration                :integer
#  width                   :integer
#  height                  :integer
#  fps                     :integer
#  archived_at             :datetime
#  created_at              :datetime
#  updated_at              :datetime
#

require 'spec_helper'

describe Video do
  let(:encoding_id) { 'ab6be8bb1bcf506842264304bc1bb479' }
  
  context "with valid attributes" do
    subject { Factory(:video) }
    
    its(:user)                    { should be_present               }
    its(:panda_video_id)          { should be_present               }
    its(:title)                   { should == "Railscast Intro"     }
    its(:token)                   { should =~ /[a-z0-9]{8}/         }
    its(:hits_cache)              { should == 0                     }
    its(:bandwidth_s3_cache)      { should == 0                     }
    its(:bandwidth_us_cache)      { should == 0                     }
    its(:bandwidth_eu_cache)      { should == 0                     }
    its(:bandwidth_as_cache)      { should == 0                     }
    its(:bandwidth_jp_cache)      { should == 0                     }
    its(:bandwidth_unknown_cache) { should == 0                     }
    its(:requests_s3_cache)       { should == 0                     }
    its(:requests_us_cache)       { should == 0                     }
    its(:requests_eu_cache)       { should == 0                     }
    its(:requests_as_cache)       { should == 0                     }
    its(:requests_jp_cache)       { should == 0                     }
    its(:requests_unknown_cache)  { should == 0                     }
    its(:original_filename)       { should == 'railscast_intro.mov' }
    its(:video_codec)             { should == 'h264'                }
    its(:audio_codec)             { should == 'aac'                 }
    its(:extname)                 { should == 'mov'                }
    its(:file_size)               { should == 123456                }
    its(:duration)                { should == 12345                 }
    its(:width)                   { should == 640                   }
    its(:height)                  { should == 480                   }
    its(:fps)                     { should == 30                    }
    its(:archived_at)             { should be_nil                   }
    
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
      before(:each) { VCR.insert_cassette('video/pandize') }
      
      let(:video) { Factory(:video, :user => Factory(:user, :video_settings => { :webm => "1" })) }
      
      it "should set the state as :encodings from :pending" do
        video.should be_pending
        video.pandize
        video.should be_encodings
      end
      
      describe "callbacks" do
        describe "before_transition :on => :pandize, :do => :set_encoding_info" do
          it "should send a get request to Panda" do
            video.stub!(:create_encodings => true, :delay_check_panda_encodings_status => true)
            Transcoder.should_receive(:get).with(:video, video.panda_video_id).and_return({ :extname => '.mp4', :original_filename => 'blabla.mp4' })
            video.pandize
          end
          
          it "should set video information fetched from Panda" do
            video.stub!(:create_encodings => true, :delay_check_panda_encodings_status => true)
            Transcoder.should_receive(:get).with(:video, video.panda_video_id).and_return({
              :original_filename => 'élevé de soleil à mañaguä.mp4', :video_codec => 'h264', :audio_codec => 'aac',
              :extname => '.mp4', :file_size => 17236, :duration => 1160, :width => 640, :height => 320, :fps => 24
            })
            video.pandize
            video.original_filename.should == "lev_de_soleil_ma_agu.mp4"
            video.video_codec.should       == "h264"
            video.audio_codec.should       == "aac"
            video.extname.should           == "mp4"
            video.file_size.should         == 17236
            video.duration.should          == 1160
            video.width.should             == 640
            video.height.should            == 320
            video.fps.should               == 24
            video.title.should             == "élevé De Soleil à Mañaguä"
          end
          
          it "should set beautiful title" do
            video.stub!(:create_encodings => true, :delay_check_panda_encodings_status => true)
            Transcoder.should_receive(:get).with(:video, video.panda_video_id).and_return({
              :original_filename => 'iPhone_3GS_voiceover.mp4', :video_codec => 'h264', :audio_codec => 'aac',
              :extname => '.mp4', :file_size => 17236, :duration => 1160, :width => 640, :height => 320, :fps => 24
            })
            video.pandize
            video.title.should == "iPhone 3GS Voiceover"
          end
        end
        
        describe "after_transition :on => :pandize, :do => :create_encodings" do
          before(:each) do
            mp4_sd_profile = Factory(:video_profile, :min_width => 0, :min_height => 0, :extname => 'mp4', :name => '_sd') # SD
            mp4_hq_profile = Factory(:video_profile, :min_width => 854, :min_height => 480, :extname => 'mp4', :name => '_hq') # HQ
            mp4_hd_profile = Factory(:video_profile, :min_width => 1280, :min_height => 720, :extname => 'mp4', :name => '_hd') # HD
            @mp4_sd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => mp4_sd_profile)
            @mp4_hq_profile_version = Factory(:video_profile_version, :state => 'active', :profile => mp4_hq_profile)
            @mp4_hd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => mp4_hd_profile)
            webm_sd_profile = Factory(:video_profile, :min_width => 0, :min_height => 0, :extname => 'webm', :name => '_sd') # SD
            webm_hq_profile = Factory(:video_profile, :min_width => 854, :min_height => 480, :extname => 'webm', :name => '_hq') # HQ
            webm_hd_profile = Factory(:video_profile, :min_width => 1280, :min_height => 720, :extname => 'webm', :name => '_hd') # HD
            @webm_sd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => webm_sd_profile)
            @webm_hq_profile_version = Factory(:video_profile_version, :state => 'active', :profile => webm_hq_profile)
            @webm_hd_profile_version = Factory(:video_profile_version, :state => 'active', :profile => webm_hd_profile)
          end
          
          # MP4 Input file example  SD minW:0 minH:0  HQ minW:640 minH:360  HD minW:854 minH:480
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
          
          #WebM Input file example  SD minW:0 minH:0  HQ minW:854 minH:480  HD minW:1280 minH:720
          # 1)  320x240             320x240           -                     -
          # 2)  480x270             480x270           -                     -
          # 3)  640x360             640x360           -                     -
          # 4)  640x480             -                 640x480               -
          # 5)  848x480             -                 848x480               -
          # 6)  864x540             -                 768x480               -
          # 7)  1280x544            -                 854x363               1280x544
          # 8)  1280x720            -                 854x480               1280x720
          # 9)  720x1280 (iPhone4)  -                 270x480               405x720
          # 10) 1920x1080           -                 854x480               1280x720
          
          it "should create encodings for each profile that is active and video width >= min_width OR video height >= min_height: 1 mp4 (SD) profile + 1 webm (SD) profile" do
            [[320,240], [480,270], [640,360]].each do |size|
              video.stub!(:set_encoding_info => true, :delay_check_panda_encodings_status => true)
              video.update_attribute(:width, size[0])
              video.update_attribute(:height, size[1])
              video.pandize
              video.encodings.size.should == 2
            end
          end
          
          it "should create encodings for each profile that is active and video width >= min_width OR video height >= min_height: 2 mp4 (SD/HQ) profile + 1 webm (HQ) profile" do
            [[640,480], [848,480], [768,480]].each do |size|
              video.stub!(:set_encoding_info => true, :delay_check_panda_encodings_status => true)
              video.update_attribute(:width, size[0])
              video.update_attribute(:height, size[1])
              video.pandize
              video.encodings.size.should == 3
            end
          end
          
          it "should create encodings for each profile that is active and video width >= min_width OR video height >= min_height: 3 mp4 (SD/HQ/HD) profile + 2 webm (HQ/HD) profile" do
            [[1280,544], [1280,720], [720,1280], [1920,1080]].each do |size|
              video.stub!(:set_encoding_info => true, :delay_check_panda_encodings_status => true)
              video.update_attribute(:width, size[0])
              video.update_attribute(:height, size[1])
              video.pandize
              video.encodings.size.should == 5
            end
          end
          
          it "should delay pandize for each encoding" do
            video.stub!(:set_encoding_info => true, :delay_check_panda_encodings_status => true)
            video.update_attribute(:width, 320)
            video.update_attribute(:height, 240)
            lambda { video.pandize }.should change(Delayed::Job, :count).by(2)
            video.encodings.size.should == 2
            Delayed::Job.first.name.should == 'VideoEncoding#pandize!'
            Delayed::Job.last.name.should == 'VideoEncoding#pandize!'
          end
        end
        
        describe "after_transition :on => :pandize, :do => :delay_check_panda_encodings_status" do
          it "should delay the checking of the encoding status" do
            video.stub!(:create_encodings => true, :set_encoding_info => true)
            lambda { video.pandize }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.last.name.should == 'Video#check_panda_encodings_status'
            Delayed::Job.last.run_at.hour.should == 5.minutes.from_now.hour
            minutes = 5.minutes.from_now.min
            (minutes-1..minutes+1).should include Delayed::Job.last.run_at.min
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ============
    # = activate =
    # ============
    describe "event(:activate) { transition :encodings => :encodings }" do
      before(:each) { VCR.insert_cassette('video_encoding/activate') }
      
      let(:video)           { Factory(:video, :state => 'encodings') }
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing') }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing') }
      
      it "should set the state as :encodings from :encodings" do
        video.should be_encodings
        video.activate
        video.should be_encodings
      end
      
      describe "callbacks" do
        describe "before_transition :on => :activate, :do => :activate_encodings" do
          it "should activate the encodings" do
            video_encoding1.should be_processing
            video_encoding2.should be_processing
            video.activate
            video_encoding1.reload.should be_active
            video_encoding2.reload.should be_active
          end
        end
        
        describe "after_transition :on => :activate, :do => :deliver_video_active, :if => :active?" do
          it "should send a 'video is ready' email to the user when all encodings are active" do
            video_encoding1.should be_processing
            video_encoding2.should be_processing
            ActionMailer::Base.deliveries.clear
            
            lambda { video.activate }.should change(ActionMailer::Base.deliveries, :size).by(1)
            
            video_encoding1.reload.should be_active
            video_encoding2.reload.should be_active
            
            last_delivery = ActionMailer::Base.deliveries.last
            last_delivery.from.should == ["no-response@sublimevideo.net"]
            last_delivery.to.should include video.user.email
            last_delivery.subject.should include "Your video “#{video.title}” is now ready!"
            last_delivery.body.should include "http://#{ActionMailer::Base.default_url_options[:host]}/videos"
          end
          
          it "should not send a 'video is ready' email to the user when the video is not ready" do
            video.stub(:active? => false)
            video_encoding1.should be_processing
            video_encoding2.fail
            video_encoding2.should be_failed
            ActionMailer::Base.deliveries.clear
            
            lambda { video.activate }.should_not change(ActionMailer::Base.deliveries, :size)
            
            video_encoding1.reload.should be_active
            video_encoding2.should be_failed
            video.should be_error
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ===========
    # = suspend =
    # ===========
    describe "event(:suspend) { transition [:pending, :encodings] => :suspended }" do
      it "should set the state as :suspended from :pending" do
        video = Factory(:video, :state => 'pending')
        video.should be_pending
        video.suspend
        video.should be_suspended
      end
      
      it "should set the state as :suspended from :encodings" do
        video = Factory(:video, :state => 'encodings')
        video.should be_encodings
        video.suspend
        video.should be_suspended
      end
      
      describe "callbacks" do
        let(:video)           { Factory(:video, :state => 'encodings') }
        let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing') }
        let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'active') }
        
        describe "before_transition :on => :suspend, :do => :suspend_encodings" do
          it "should suspend all the active encodings" do
            video_encoding1.should be_processing
            video_encoding2.should be_active
            video.suspend
            video_encoding1.reload.should be_processing
            video_encoding2.reload.should be_suspended
          end
        end
        
        describe "before_transition :on => :suspend, :do => :suspend_posterframe" do
          before(:each) do
            @video = Factory(:video, :state => 'encodings')
            VCR.use_cassette('video_encoding/activate') { @video.activate }
            VCR.insert_cassette('video/suspend')
          end
          
          it "should suspend the posterframe" do
            @video.posterframe.stub!(:path).and_return("posterframe.jpg")
            s3_int = Aws::S3Interface.new(S3.access_key_id, S3.secret_access_key)
            s3_int.get_acl(@video.posterframe.s3_bucket, "active#{@video.posterframe.path}")[:object].should include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
            @video.suspend
            s3_int.get_acl(@video.posterframe.s3_bucket, "suspended#{@video.posterframe.path}")[:object].should_not include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
          end
        end
        
      end
      
      after(:each) { VCR.eject_cassette }
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
        let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing') }
        let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'suspended') }
        
        describe "before_transition :on => :unsuspend, :do => :unsuspend_encodings" do
          it "should unsuspend all the suspended encodings" do
            video_encoding1.should be_processing
            video_encoding2.should be_suspended
            video.unsuspend
            video_encoding1.reload.should be_processing
            video_encoding2.reload.should be_active
          end
        end
        
        describe "before_transition :on => :suspend, :do => :unsuspend_posterframe" do
          before(:each) do
            @video = Factory(:video, :state => 'encodings')
            VCR.use_cassette('video_encoding/activate') { @video.activate }
            VCR.use_cassette('video/suspend') { @video.suspend }
            VCR.insert_cassette('video/suspend')
          end
          
          it "should suspend the posterframe" do
            @video.posterframe.stub!(:path).and_return("posterframe.jpg")
            s3_int = Aws::S3Interface.new(S3.access_key_id, S3.secret_access_key)
            s3_int.get_acl(@video.posterframe.s3_bucket, "suspended#{@video.posterframe.path}")[:object].should_not include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
            @video.unsuspend
            s3_int.get_acl(@video.posterframe.s3_bucket, "active#{@video.posterframe.path}")[:object].should include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
          end
        end
        
      end
      
    end
    
    # ===========
    # = archive =
    # ===========
    describe "event(:archive) { transition [:pending, :encodings, :suspended] => :archived }" do
      before(:each) { VCR.insert_cassette('video/archive') }
      
      it "should set the state as :archived from :pending" do
        video = Factory(:video, :state => 'pending')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video => true, :remove_posterframe! => true)
        video.should be_pending
        video.archive
        video.should be_archived
      end
      
      it "should set the state as :archived from :encodings" do
        video = Factory(:video, :state => 'encodings')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video => true, :remove_posterframe! => true)
        video.should be_encodings
        video.archive
        video.should be_archived
      end
      
      it "should set the state as :archived from :suspended" do
        video = Factory(:video, :state => 'suspended')
        video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video => true, :remove_posterframe! => true)
        video.should be_suspended
        video.archive
        video.should be_archived
      end
      
      describe "callbacks" do
        let(:video) { Factory(:video, :state => 'encodings') }
        
        describe "before_transition :on => :archive, :do => [:set_archived_at, :archive_encodings]" do
          it "should set archived_at to now" do
            video.stub!(:archive_encodings => true, :remove_video => true, :remove_posterframe! => true)
            video.archive
            video.archived_at.should be_present
          end
        end
        
        describe "before_transition :on => :archive, :do => :archive_encodings" do
          it "should delay the archive of every video encoding" do
            video.stub!(:set_archived_at => true, :remove_video => true, :remove_posterframe! => true)
            pending_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'pending')
            pending_video_encoding.should be_pending
            
            encoding_video_encoding = Factory(:video_encoding, :video => video)
            VCR.use_cassette('video_encoding/pandize') { encoding_video_encoding.pandize }
            encoding_video_encoding.should be_processing
            
            active_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing')
            VCR.use_cassette('video_encoding/activate') { active_video_encoding.activate }
            active_video_encoding.should be_active
            
            deprecated_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'deprecated')
            deprecated_video_encoding.should be_deprecated
            
            suspended_video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing')
            VCR.use_cassette('video_encoding/activate') { suspended_video_encoding.activate }
            VCR.use_cassette('video_encoding/suspend') { suspended_video_encoding.suspend }
            suspended_video_encoding.should be_suspended
            
            lambda { video.archive }.should change(Delayed::Job, :count).by(4)
            Delayed::Job.last.name.should == 'VideoEncoding#archive'
            VCR.use_cassette('video_encoding/archive') { Delayed::Worker.new(:quiet => true).work_off }
            
            pending_video_encoding.reload.should be_archived
            encoding_video_encoding.reload.should be_archived
            active_video_encoding.reload.should be_archived
            deprecated_video_encoding.reload.should_not be_archived
            suspended_video_encoding.reload.should be_archived
          end
        end
        
        describe "after_transition :on => :archive, :do => :remove_video" do
          it "should delay the DELETE request to Panda remove the original video file" do
            video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_posterframe! => true)
            video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing')
            VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
            video.archive
            Delayed::Job.last.name.should == 'Module#delete'
          end
        end
        
        describe "after_transition  :on => :archive, :do => :remove_posterframe!" do
          it "should remove the posterframe" do
            video.stub!(:set_archived_at => true, :archive_encodings => true, :remove_video => true)
            video_encoding = Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing')
            video_encoding.profile.stub!(:posterframeable? => true)
            VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
            video.posterframe.should be_present
            video.posterframe.thumb.should be_present
            video.archive
            video.posterframe.should_not be_present
            video.posterframe.thumb.should_not be_present
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
  describe "life cycle" do
    before(:each) do
      @vpv1 = Factory(:video_profile_version)
      @vpv1.profile.update_attribute(:posterframeable, true)
      @vpv2 = Factory(:video_profile_version)
      VCR.use_cassette('video_profile_version/pandize') do
        @vpv1.pandize
        @vpv2.pandize
      end
      @vpv1.activate
      @vpv2.activate
    end
    
    let(:video) { Factory(:video, :panda_video_id => 'a'*32) }
    
    it "should be consistent" do
      @vpv1.should be_active
      @vpv2.should be_active
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
      
      VCR.use_cassette('video_encoding/pandize') do
        Delayed::Worker.new(:quiet => true).work_off
        video.encodings[0].reload.should be_processing
        video.encodings[1].reload.should be_processing
      end
      
      VCR.use_cassette('video_encoding/activate') do
        video.encodings[0].profile.should be_posterframeable
        video.posterframe.should_not be_present
        video.activate
        video.encodings[0].reload.should be_active
        video.encodings[1].reload.should be_active
        video.should_not be_first_processing
        video.should_not be_error
        video.should be_active
        video.reload.posterframe.should be_present
        video.posterframe.thumb.should be_present
      end
      
      VCR.use_cassette('video/suspend') { video.suspend }
      video.should be_suspended
      video.encodings[0].should be_suspended
      video.encodings[1].should be_suspended
      
      video.unsuspend
      video.encodings[0].reload.should be_active
      video.encodings[1].reload.should be_active
      video.should be_encodings
      video.should_not be_first_processing
      video.should_not be_error
      video.should be_active
      
      VCR.use_cassette('video/archive') do
        video.archive
        video.should be_archived
        Delayed::Worker.new(:quiet => true).work_off
      end
      video.encodings[0].reload.should be_archived
      video.encodings[1].reload.should be_archived
      video.encodings[0].file.should_not be_present
      video.encodings[1].file.should_not be_present
      video.posterframe.should_not be_present
      video.posterframe.thumb.should_not be_present
    end
  end
  
  describe "Class Methods" do
    describe ".panda_s3_url" do
      it "should be get from Panda" do
        VCR.use_cassette('video/class_methods') do
          Video.panda_s3_url.should == "http://dev.sublimevideo.panda.s3.amazonaws.com"
        end
      end
    end
  end
  
  describe "Instance Methods" do
    # SOMETIMES PROBLEM HERE WHEN RUNNING ALL SPECS
    let(:video) { Factory(:video, :original_filename => 'hey_ho.mp4', :extname => 'mp4', :file_size => 1000) }
    
    describe "#name" do
      it "should return name used in the filename of the Video file" do
        video.original_filename.should == 'hey_ho.mp4'
        video.extname.should == 'mp4'
        video.name.should == 'hey_ho'
      end
      
      it "should return '' if no original_filename" do
        video.update_attribute(:original_filename, nil)
        video.original_filename.should be_nil
        video.extname.should == 'mp4'
        video.name.should == ''
      end
      
      it "should return '' if no original_filename" do
        video.update_attribute(:extname, nil)
        video.original_filename.should == 'hey_ho.mp4'
        video.extname.should be_nil
        video.name.should == ''
      end
    end
    
    describe "#total_size" do
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :state => 'processing', :file_size => 42, :panda_encoding_id => encoding_id) }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :state => 'active', :file_size => 38, :panda_encoding_id => encoding_id) }
      let(:video_encoding3) { Factory(:video_encoding, :video => video, :state => 'active', :file_size => 10, :panda_encoding_id => encoding_id) }
      let(:video_encoding4) { Factory(:video_encoding, :video => video, :state => 'deprecated', :file_size => 20, :panda_encoding_id => encoding_id) }
      
      it "should return total storage (reference video size + encoding sizes) only for active encodings" do
        video.file_size.should == 1000
        video_encoding1.file_size.should == 42
        video_encoding2.file_size.should == 38
        video_encoding3.file_size.should == 10
        video_encoding4.file_size.should == 20
        video.total_size.should == 1090
      end
      
      it "should return total storage (reference video size + encoding sizes) even if video.file_size is nil" do
        video.update_attribute(:file_size, nil)
        video_encoding1.file_size.should == 42
        video_encoding2.file_size.should == 38
        video_encoding3.file_size.should == 10
        video_encoding4.file_size.should == 20
        video.total_size.should == 90
      end
      
      it "should return total storage (reference video size + encoding sizes) even if video_encoding.file_size is nil" do
        video_encoding2.update_attribute(:file_size, nil)
        video.file_size.should == 1000
        video_encoding1.file_size.should == 42
        video_encoding2.file_size.should be_nil
        video_encoding3.file_size.should == 10
        video_encoding4.file_size.should == 20
        video.total_size.should == 1052
      end
    end
    
    describe "delegated states" do
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing') }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'active') }
      
      describe "#first_processing?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_first_processing
        end
        
        it "should return false if video is in the encodings state and has no encoding first processing" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.file = File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
          video_encoding1.save
          video_encoding1.should_not be_first_processing
          video_encoding2.should be_active
          video.should_not be_first_processing
        end
        
        it "should return true if any video encoding of a video is currently first processing" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.stub!(:first_processing? => true)
          video_encoding1.should be_first_processing
          video.should be_first_processing
        end
      end
      
      describe "#reprocessing?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_reprocessing
        end
        
        it "should return true if video is in the encodings state and has no encoding reprocessing" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.file = File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
          video_encoding1.save
          video_encoding1.should be_reprocessing
          video_encoding2.should_not be_reprocessing
          video.should be_reprocessing
        end
        
        it "should return false if no video encoding of a video is currently reprocessing" do
          video_encoding1.should_not be_reprocessing
          video.reload.should_not be_reprocessing
        end
      end
      
      describe "#processing?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_processing
        end
        
        it "should return false if video is in the encodings state and has no encoding processing" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.update_attribute(:state, 'failed')
          video_encoding1.should_not be_processing
          video_encoding2.should_not be_processing
          video.should_not be_processing
        end
        
        it "should return true if any video encoding of a video is currently processing" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.should be_processing
          video.should be_processing
        end
      end
      
      describe "#active?" do
        it "should return false if video is not in the encodings state" do
          video.should_not be_active
        end
        
        it "should return false if video is in the encodings state and has not all encoding active" do
          video.update_attribute(:state, 'encodings')
          video_encoding1.should be_processing
          video_encoding2.should be_active
          video.should_not be_active
        end
        
        it "should return true if all the encodings of a video are active" do
          video.update_attribute(:state, 'encodings')
          VCR.use_cassette('video_encoding/activate') { video_encoding1.activate }
          video_encoding1.should be_active
          video_encoding2.should be_active
          video.reload.should be_active
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
    
    # describe "#hd?" do
    #   it "should return true if width >= 720" do
    #     video.update_attribute(:width, 720)
    #     video.should be_hd
    #   end
    #   
    #   it "should return true if height >= 1280" do
    #     video.update_attribute(:height, 1280)
    #     video.should be_hd
    #   end
    #   
    #   it "should return false if width < 720 and height < 1280" do
    #     video.update_attributes(:width => 719, :height => 1279)
    #     video.should_not be_hd
    #   end
    # end
    
    describe "check_panda_encodings_status" do
      before(:each) { VCR.insert_cassette('video/pandize') }
      
      let(:video) { Factory(:video, :state => 'encodings') }
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => '1'*32, :state => 'processing', :profile_version => Factory(:video_profile_version, :profile => Factory(:video_profile, :min_width => 500, :posterframeable => true))) }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :panda_encoding_id => encoding_id, :state => 'processing', :profile_version => Factory(:video_profile_version, :profile => Factory(:video_profile, :min_width => 200, :posterframeable => true))) }
      
      it "should not even check Panda if the video is not currently in the processing state" do
        video_encoding1.update_attribute(:state, 'active')
        video_encoding2.update_attribute(:state, 'active')
        video_encoding1.should be_active
        video_encoding2.should be_active
        video.reload.should_not be_first_processing
        Transcoder.should_not_receive(:get)
        lambda { video.check_panda_encodings_status }.should_not change(Delayed::Job, :count)
        video.should be_active
      end
      
      it "should activate the video if all the encodings are complete on Panda" do
        video_encoding1.stub!(:activate).and_return(true)
        video_encoding2.stub!(:activate).and_return(true)
        video_encoding1.should be_processing
        video_encoding2.should be_processing
        video.should be_first_processing
        Transcoder.should_receive(:get).with([:video, :encodings], video.panda_video_id).and_return([{ :id => '1'*32, :status => 'success' }, { :id => encoding_id, :status => 'success' }])
        video.should_receive(:activate).and_return(true)
        lambda { video.check_panda_encodings_status }.should_not change(Delayed::Job, :count)
      end
      
      it "should not activate the video and delay check_panda_encodings_status if any of the encodings are still processing on Panda" do
        video_encoding1.should be_processing
        video_encoding2.should be_processing
        video.should be_first_processing
        Transcoder.should_receive(:get).with([:video, :encodings], video.panda_video_id).and_return([{ :id => '1'*32, :status => 'processing' }, { :id => encoding_id, :status => 'success' }])
        video.should_not_receive(:activate)
        lambda { video.check_panda_encodings_status }.should change(Delayed::Job, :count).by(1)
        Delayed::Job.last.name.should == 'Video#check_panda_encodings_status'
      end
      
      it "should activate each video encoding with the 'success' panda status and not re-call delay_check_panda_encodings_status" do
        video_encoding1.should be_processing
        video_encoding2.should be_processing
        video.posterframe.should_not be_present
        video.should be_first_processing
        Transcoder.should_receive(:get).with([:video, :encodings], video.panda_video_id).and_return([{ :id => '1'*32, :status => 'success' }, { :id => encoding_id, :status => 'fail' }])
        Transcoder.should_receive(:get).with(:encoding, video_encoding1.panda_encoding_id).and_return({ :status => 'success', :file_size => 1234, :started_encoding_at => Time.now.to_s, :encoding_time => 1, :width => 640, :height => 480 })
        HoptoadNotifier.should_receive(:notify, "VideoEncoding (#{video_encoding1.id}) panda encoding is failed.")
        lambda { video.check_panda_encodings_status }.should_not change(Delayed::Job, :count)
        video_encoding1.reload.should be_active
        video_encoding2.reload.should be_failed
        video.reload.should be_error
      end
      
      it "should not re-call delay_check_panda_encodings_status if all encodings are not complete and if no encoding is processing anymore, should also fail each video with the 'failed' panda status, send an Hoptoad notification and activate individually videos with the 'sucess' panda status" do
        video_encoding1.should be_processing
        video_encoding2.should be_processing
        video.should be_first_processing
        Transcoder.should_receive(:get).with([:video, :encodings], video.panda_video_id).and_return([{ :id => '1'*32, :status => 'fail' }, { :id => encoding_id, :status => 'success' }])
        Transcoder.should_receive(:get).with(:encoding, video_encoding2.panda_encoding_id).and_return({ :status => 'success', :file_size => 1234, :started_encoding_at => Time.now.to_s, :encoding_time => 1, :width => 1, :height => 1 })
        HoptoadNotifier.should_receive(:notify, "VideoEncoding (#{video_encoding1.id}) panda encoding is failed.")
        lambda { video.check_panda_encodings_status }.should_not change(Delayed::Job, :count)
        video_encoding1.reload.should be_failed
        video_encoding2.reload.should be_active
        video.reload.should_not be_first_processing
        video.should be_error
      end
      
      after(:each) { VCR.eject_cassette }
    end
  end
  
end
