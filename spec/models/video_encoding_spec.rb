# == Schema Information
#
# Table name: video_encodings
#
#  id                       :integer         not null, primary key
#  video_id                 :integer
#  video_profile_version_id :integer
#  state                    :string(255)
#  file                     :string(255)
#  panda_encoding_id        :string(255)
#  started_encoding_at      :datetime
#  encoding_time            :integer
#  extname                  :string(255)
#  file_size                :integer
#  width                    :integer
#  height                   :integer
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe VideoEncoding do
  let(:id) { 'ab6be8bb1bcf506842264304bc1bb479' }
  
  context "with valid attributes" do
    subject { Factory(:video_encoding) }
    
    its(:video)               { should be_present }
    its(:profile_version)     { should be_present }
    its(:panda_encoding_id)   { should be_nil     }
    its(:started_encoding_at) { should be_present }
    its(:encoding_time)       { should == 1       }
    its(:extname)             { should == 'mp4'  }
    its(:file_size)           { should == 123456  }
    its(:width)               { should == 640     }
    its(:height)              { should == 480     }
    
    it { should be_valid }
  end
  
  describe "Validations" do
    it "should validate presence of :video" do
      video = Factory.build(:video_encoding, :video => nil)
      video.should_not be_valid
      video.should have(1).error_on(:video)
    end
    
    it "should validate presence of :profile_version" do
      video = Factory.build(:video_encoding, :profile_version => nil)
      video.should_not be_valid
      video.should have(1).error_on(:profile_version)
    end
  end
  
  describe "State Machine" do
    
    describe "initial state" do
      it "should be pending" do
        Factory(:video_encoding).should be_pending
      end
    end
    
    # ===========
    # = pandize =
    # ===========
    describe "event(:pandize) { transition :pending => :processing }" do
      before(:each) { VCR.insert_cassette('video_encoding/pandize') }
      
      it "should set the state as :processing from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        video_encoding.pandize
        video_encoding.should be_processing
      end
      
      describe "callbacks" do
        let(:video_encoding) { Factory(:video_encoding, :extname => nil, :width => nil, :height => nil) }
        let(:params) { { :video_id => video_encoding.video.panda_video_id, :profile_id => video_encoding.profile_version.panda_profile_id } }
        
        describe "before_transition :on => :pandize, :do => :create_panda_encoding_and_set_info" do
          it "should send a post request to Panda" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({})
            video_encoding.pandize
          end
          
          it "should set encoding info" do
            video_encoding.pandize
            video_encoding.panda_encoding_id.should == id
            video_encoding.extname.should           == 'mp4'
            video_encoding.width.should             == 480
            video_encoding.height.should            == 320
            video_encoding.should be_processing
          end
          
          it "should send us a notification via Hoptoad if creation has failed on Panda" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({ :error => "RecordNotFound", :message => "Couldn't find Video with ID=#{id}" })
            HoptoadNotifier.should_receive(:notify).with("VideoEncoding (#{video_encoding.id}) panda encoding (panda_encoding_id: #{video_encoding.panda_encoding_id}) creation error: Couldn't find Video with ID=#{id}")
            video_encoding.pandize
            video_encoding.should be_pending
          end
        end
        
        describe ":processing state validations" do
          it "should stay pending if panda_encoding_id is missing" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({ :extname => '.mp4', :width => 480, :height => 320 })
            video_encoding.pandize
            video_encoding.panda_encoding_id.should be_nil
            video_encoding.should be_pending
          end
          
          it "should stay pending if extname is missing" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :width => 480, :height => 320 })
            video_encoding.pandize
            video_encoding.extname.should be_nil
            video_encoding.should be_pending
          end
          
          it "should stay pending if width is missing" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :extname => '.mp4', :height => 320 })
            video_encoding.pandize
            video_encoding.width.should be_nil
            video_encoding.should be_pending
          end
          
          it "should stay pending if height is missing" do
            Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :extname => '.mp4', :width => 480 })
            video_encoding.pandize
            video_encoding.height.should be_nil
            video_encoding.should be_pending
          end
        end
        
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ============
    # = activate =
    # ============
    describe "event(:activate) { transition :processing => :active }" do
      before(:each) { VCR.insert_cassette('video_encoding/activate') }
      
      # SOMETIMES PROBLEM HERE WHEN RUNNING ALL SPECS
      let(:video)           { Factory(:video) }
      let(:video_encoding1) { Factory(:video_encoding, :video => video, :panda_encoding_id => id, :state => 'processing', :profile_version => Factory(:video_profile_version, :profile => Factory(:video_profile, :min_width => 200, :thumbnailable => true))) }
      let(:video_encoding2) { Factory(:video_encoding, :video => video, :panda_encoding_id => id, :state => 'processing', :profile_version => Factory(:video_profile_version, :profile => Factory(:video_profile, :min_width => 500, :thumbnailable => true))) }
      
      it "should set the state as :active from :processing" do
        video_encoding1.should be_processing
        video_encoding1.activate
        video_encoding1.should be_active
      end
      
      describe "callbacks" do
        describe "before_transition :on => :activate, :do => :set_file_added_at" do
          it "should set file_added_at" do
            video_encoding1.file_added_at.should_not be_present
            video_encoding1.activate
            video_encoding1.file_added_at.should be_present
          end
        end
        
        describe "before_transition :on => :activate, :do => :set_file" do
          it "should set file to the encoding's file" do
            video_encoding1.activate
            video_encoding1.file.url.should =~ %r(videos/#{video_encoding1.video.token}/#{video_encoding1.video.name}#{video_encoding1.profile.name}.#{video_encoding1.extname})
          end
        end
        
        describe "before_transition :on => :activate, :do => :set_encoding_info" do
          it "should send a get request to Panda" do
            video_encoding1.stub!(:set_file => true, :set_video_posterframe => true, :deprecate_encodings => true, :delete_panda_encoding => true, :conform_to_video_state => true)
            Transcoder.should_receive(:get).with(:encoding, id).and_return({})
            video_encoding1.activate
          end
          
          it "should set encoding info" do
            video_encoding1.stub!(:set_file => true, :set_video_posterframe => true, :deprecate_encodings => true, :delete_panda_encoding => true, :conform_to_video_state => true)
            video_encoding1.activate
            video_encoding1.file_size.should           == 125465
            video_encoding1.started_encoding_at.should == Time.parse("2010/06/08 17:15:17 +0000")
            video_encoding1.encoding_time.should       == 12
            video_encoding1.encoding_status.should     == 'success'
            video_encoding1.should be_active
          end
        end
        
        describe "before_transition :on => :activate, :do => :set_video_posterframe" do
          it "should set video posterframe if profile is thumbnailable" do
            video_encoding1.stub!(:set_encoding_info => true, :set_file => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
            video_encoding2.stub!(:set_encoding_info => true, :set_file => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
            
            video_encoding1.activate
            video_encoding1.video.posterframe.url.should_not be_present
            video_encoding1.video.posterframe.thumb.url.should_not be_present
            
            video_encoding2.activate
            video_encoding2.video.posterframe.url.should =~ %r(videos/#{video_encoding2.video.token}/posterframe.jpg)
            video_encoding2.video.posterframe.thumb.url.should =~ %r(videos/#{video_encoding2.video.token}/thumb_posterframe.jpg)
          end
          
          it "should not set video posterframe if profile is not thumbnailable" do
            video_encoding1.stub!(:set_encoding_info => true, :set_file => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
            video_encoding1.profile.stub!(:thumbnailable? => false)
            video_encoding1.activate
            video_encoding1.video.posterframe.should_not be_present
            video_encoding1.video.posterframe.thumb.should_not be_present
          end
        end
        
        describe ":active state validations" do
          it "should stay processing if the panda encoding status is not 'success'" do
            Transcoder.should_receive(:get).with(:encoding, id).and_return({ :file_size => 125465, :started_encoding_at => "2010/06/08 17:15:17 +0000", :encoding_time => 12, :status => 'processing' })
            video_encoding1.activate
            video_encoding1.should be_processing
          end
          
          it "should stay pending if file_size is missing" do
            Transcoder.should_receive(:get).with(:encoding, id).and_return({ :started_encoding_at => "2010/06/08 17:15:17 +0000", :encoding_time => 12, :status => 'success' })
            video_encoding1.activate
            video_encoding1.file_size.should be_nil
            video_encoding1.should be_processing
          end
          
          it "should stay pending if started_encoding_at is missing" do
            Transcoder.should_receive(:get).with(:encoding, id).and_return({ :file_size => 125465, :encoding_time => 12, :status => 'success' })
            video_encoding1.activate
            video_encoding1.started_encoding_at.should be_nil
            video_encoding1.should be_processing
          end
          
          it "should stay pending if encoding_time is missing" do
            Transcoder.should_receive(:get).with(:encoding, id).and_return({ :file_size => 125465, :started_encoding_at => "2010/06/08 17:15:17 +0000", :status => 'success' })
            video_encoding1.activate
            video_encoding1.encoding_time.should be_nil
            video_encoding1.should be_processing
          end
        end
        
        describe "after_transition :on => :activate, :do => :deprecate_encodings" do
          it "should deprecate all the active encodings for the same video and profile" do
            active_video_encoding = Factory(:video_encoding, :state => 'active', :video => video_encoding1.video, :profile_version => video_encoding1.profile_version)
            video_encoding1.activate
            video_encoding1.reload.should be_active
            active_video_encoding.reload.should be_deprecated
          end
          
          it "should deprecate all the failed encodings for the same video and profile" do
            failed_video_encoding = Factory(:video_encoding, :state => 'failed', :video => video_encoding1.video, :profile_version => video_encoding1.profile_version, :panda_encoding_id => id)
            video_encoding1.activate
            failed_video_encoding.reload.should be_deprecated
          end
        end
        
        describe "after_transition :on => :activate, :do => :delete_panda_encoding" do
          it "should remove the encoding reference (and file) on Panda" do
            Transcoder.should_receive(:delete).with(:encoding, id).and_return(true)
            video_encoding1.activate
          end
        end
        
        describe "after_transition :on => :activate, :do => :conform_to_video_state" do
          it "should suspend the encoding if video is suspended" do
            VCR.use_cassette('video/suspend') { video_encoding1.video.suspend }
            video_encoding1.video.should be_suspended
            video_encoding1.activate
            video_encoding1.should be_suspended
          end
        end
        
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ========
    # = fail =
    # ========
    describe "event(:fail) { transition [:pending, :processing] => :failed }" do
      it "should set the state as :failed from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        video_encoding.fail
        video_encoding.should be_failed
      end
      
      it "should set the state as :failed from :processing" do
        video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing', :extname => 'mp4', :encoding_time => 1, :started_encoding_at => Time.now)
        video_encoding.should be_processing
        video_encoding.fail
        video_encoding.should be_failed
      end
    end
    
    # =============
    # = deprecate =
    # =============
    describe "event(:deprecate) { transition [:active, :failed] => :deprecated }" do
      before(:each) { VCR.insert_cassette('video_encoding/deprecate') }
      
      it "should set the state as :deprecated from :active" do
        video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'active')
        video_encoding.should be_active
        video_encoding.deprecate
        video_encoding.should be_deprecated
      end
      
      it "should set the state as :deprecated from :failed" do
        video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'failed')
        video_encoding.should be_failed
        video_encoding.deprecate
        video_encoding.should be_deprecated
      end
      
      describe "callbacks" do
        let(:video_encoding) { Factory(:video_encoding, :panda_encoding_id => id, :state => 'failed') }
        
        describe "before_transition :on => :deprecate, :do => :set_file_removed_at" do
          it "should set file_removed_at" do
            video_encoding.file_removed_at.should_not be_present
            video_encoding.deprecate
            video_encoding.file_removed_at.should be_present
          end
        end
        
        describe "before_transition :failed => :deprecated, :do => :delete_panda_encoding" do
          it "should remove the encoding reference (and file) on Panda" do
            Transcoder.should_receive(:delete).with(:encoding, id).and_return(true)
            video_encoding.deprecate
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ===========
    # = suspend =
    # ===========
    describe "event(:suspend) { transition :active => :suspended }" do
      before(:each) do
        @video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing')
        VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
        VCR.insert_cassette('video_encoding/suspend')
      end
      
      it "should set the state as :suspended from :active" do
        @video_encoding.should be_active
        @video_encoding.suspend
        @video_encoding.should be_suspended
      end
      
      describe "callbacks" do
        
        it "before_transition => #block_video should set the READ right to NOBODY (or OWNER if it's enough)" do
          @video_encoding.file.path.should be_present
          s3_int = Aws::S3Interface.new(S3.access_key_id, S3.secret_access_key)
          s3_int.get_acl(@video_encoding.file.s3_bucket, "active#{@video_encoding.file.path}")[:object].should include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
          @video_encoding.suspend
          s3_int.get_acl(@video_encoding.file.s3_bucket, "suspended#{@video_encoding.file.path}")[:object].should_not include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # =============
    # = unsuspend =
    # =============
    describe "event(:unsuspend) { transition :suspended => :active }" do
      before(:each) do
        @video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing')
        VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
        VCR.use_cassette('video_encoding/activate') { @video_encoding.suspend }
        VCR.insert_cassette('video_encoding/unsuspend')
      end
      
      it "should set the state as :active from :suspended" do
        @video_encoding.should be_suspended
        @video_encoding.unsuspend
        @video_encoding.should be_active
      end
      
      describe "callbacks" do
        it "before_transition => #unblock_video should set the READ right to WORLD" do
          @video_encoding.file.path.should be_present
          s3_int = Aws::S3Interface.new(S3.access_key_id, S3.secret_access_key)
          s3_int.get_acl(@video_encoding.file.s3_bucket, "suspended#{@video_encoding.file.path}")[:object].should_not include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
          @video_encoding.unsuspend
          s3_int.get_acl(@video_encoding.file.s3_bucket, "active#{@video_encoding.file.path}")[:object].should include '<Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant>'
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # ===========
    # = archive =
    # ===========
    describe "event(:archive) { transition [:pending, :processing, :failed, :active, :deprecated, :suspended] => :archived }" do
      before(:each) { VCR.insert_cassette('video_encoding/archive') }
      
      it "should set the state as :deprecated from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        video_encoding.archive
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :processing" do
        video_encoding = Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing')
        video_encoding.should be_processing
        video_encoding.archive
        video_encoding.should be_valid
        video_encoding.reload.should be_archived
      end
      
      it "should set the state as :deprecated from :failed" do
        video_encoding = Factory(:video_encoding, :state => 'failed')
        video_encoding.should be_failed
        video_encoding.archive
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :active" do
        video_encoding = Factory(:video_encoding, :state => 'active')
        video_encoding.should be_active
        video_encoding.archive
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :deprecated" do
        video_encoding = Factory(:video_encoding, :state => 'deprecated')
        video_encoding.should be_deprecated
        video_encoding.archive
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :suspended" do
        video_encoding = Factory(:video_encoding, :state => 'suspended')
        video_encoding.should be_suspended
        video_encoding.archive
        video_encoding.should be_archived
      end
      
      describe "callbacks" do
        let(:video_encoding) { Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing') }
        
        describe "before_transition :on => :archive, :do => :set_file_removed_at" do
          it "should set file_removed_at" do
            video_encoding.file_removed_at.should_not be_present
            video_encoding.archive
            video_encoding.file_removed_at.should be_present
          end
        end
        
        describe "before_transition :on => :archive, :do => :remove_file!" do
          it "should delete the video file from S3" do
            VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
            video_encoding.should be_active
            video_encoding.file.should be_present
            video_encoding.archive
            video_encoding.file.should_not be_present
          end
        end
        
        describe "before_transition :processing => :archived, :do => :set_encoding_info" do
          it "should send a get request to Panda" do
            video_encoding.stub!(:delete_panda_encoding => true, :remove_file! => true)
            Transcoder.should_receive(:get).with(:encoding, id).and_return({})
            video_encoding.archive
          end
          
          it "should set encoding info" do
            video_encoding.stub!(:delete_panda_encoding => true, :remove_file! => true)
            video_encoding.archive
            video_encoding.file_size.should           == 125465
            video_encoding.started_encoding_at.should == Time.parse("2010/06/08 17:15:17 +0000")
            video_encoding.encoding_time.should       == 12
            video_encoding.encoding_status.should     == 'success'
            video_encoding.should be_archived
          end
        end
        
        describe "before_transition :processing => :archived, :do => :delete_panda_encoding" do
          it "should send a delete request to Panda with the panda_encoding_id" do
            video_encoding.stub!(:set_encoding_info => true, :remove_video_file! => true)
            video_encoding.should be_processing
            Transcoder.should_receive(:delete).with(:encoding, id).and_return(true)
            video_encoding.archive
          end
        end
        
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
  describe "life cycle" do
    let(:video_encoding) { Factory(:video_encoding) }
    
    it "should be consistent" do
      video_encoding.should be_pending
      VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
      video_encoding.should be_processing
      VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
      video_encoding.should be_active
      video_encoding.file_size.should be_present
      video_encoding.started_encoding_at.should be_present
      video_encoding.encoding_time.should be_present
      video_encoding.file.should be_present
      VCR.use_cassette('video_encoding/suspend') { video_encoding.suspend }
      video_encoding.should be_suspended
      video_encoding.unsuspend
      video_encoding.should be_active
      
      new_video_encoding = Factory(:video_encoding, :video => video_encoding.video, :profile_version => video_encoding.profile_version)
      new_video_encoding.should be_pending
      VCR.use_cassette('video_encoding/pandize') { new_video_encoding.pandize }
      new_video_encoding.should be_processing
      VCR.use_cassette('video_encoding/activate') { new_video_encoding.activate }
      new_video_encoding.should be_active
      new_video_encoding.file_size.should be_present
      new_video_encoding.started_encoding_at.should be_present
      new_video_encoding.encoding_time.should be_present
      new_video_encoding.file.should be_present
      video_encoding.reload.should be_deprecated
      video_encoding.file.url.should == new_video_encoding.file.url
      
      last_video_encoding = Factory(:video_encoding, :video => video_encoding.video, :profile_version => video_encoding.profile_version)
      last_video_encoding.should be_pending
      VCR.use_cassette('video_encoding/pandize') { last_video_encoding.pandize }
      last_video_encoding.should be_processing
      
      VCR.use_cassette('video_encoding/archive') { new_video_encoding.archive }
      new_video_encoding.should be_archived
      new_video_encoding.file.should_not be_present
      
      VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
      video_encoding.should be_archived
      video_encoding.file.should_not be_present
      
      VCR.use_cassette('video_encoding/archive') { last_video_encoding.archive }
      last_video_encoding.should be_archived
      last_video_encoding.file.should_not be_present
    end
  end
  
  describe "Class Methods" do
    describe ".panda_s3_url" do
      it "should be get from Panda" do
        VCR.use_cassette('video_encoding/class_methods') do
          VideoEncoding.panda_s3_url.should == "http://dev.sublimevideo.panda.s3.amazonaws.com"
        end
      end
    end
  end
  
  describe "Instance Methods" do
    let(:video_encoding) { Factory(:video_encoding, :panda_encoding_id => id, :state => 'processing') }
    
    describe "#first_processing?" do
      it "should be true if file is not present and state is processing" do
        video_encoding.should be_first_processing
      end
      
      it "should be false if file is already present and state is processing" do
        video_encoding.file = File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
        video_encoding.save
        video_encoding.should_not be_first_processing
      end
    end
    
    describe "#reprocessing?" do
      it "should be false if file is not present and state is processing" do
        video_encoding.should_not be_reprocessing
      end
      
      it "should be true if file is already present and state is processing" do
        video_encoding.file = File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
        video_encoding.save
        video_encoding.should be_reprocessing
      end
    end
  end
  
end