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
  
  context "with valid attributes" do
    subject { Factory(:video_encoding) }
    
    its(:video)               { should be_present }
    its(:profile_version)     { should be_present }
    its(:panda_encoding_id)   { should be_nil     }
    its(:started_encoding_at) { should be_nil     }
    its(:encoding_time)       { should be_nil     }
    its(:extname)             { should == '.mp4'  }
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
    
    describe "event(:pandize)" do
      it "should set the state as :encoding from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
        video_encoding.should be_encoding
      end
      
      it "should set the state as :active from :active" do
        video_encoding = Factory(:video_encoding, :state => 'active')
        video_encoding.should be_active
        VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
        video_encoding.should be_encoding
      end
      
      describe "conditions" do
        let(:video_encoding) { Factory(:video_encoding, :profile_version => Factory(:video_profile_version, :panda_profile_id => '73f93e74e866d86624a8718d21d06e4e')) }
        let(:params) { { :video_id => video_encoding.video.panda_video_id, :profile_id => video_encoding.profile_version.panda_profile_id } }
        let(:id) { 'ab6be8bb1bcf506842264304bc1bb479' }
        
        it "transition [:pending, :active] => :encoding, :if => :panda_encoding_created?" do
          Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :status => 'processing' })
          VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
          video_encoding.panda_encoding_id.should == id
          video_encoding.should be_encoding
        end
        
        it "transition :failed => :encoding, :if => :retry_encoding_succeeded? with a panda_encoding_id" do
          VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
          video_encoding.fail
          Transcoder.should_receive(:retry).with(:encoding, id).and_return({ :id => id, :status => 'processing' })
          VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
          video_encoding.should be_encoding
        end
        
        it "transition :failed => :encoding, :if => :retry_encoding_succeeded? without a panda_encoding_id" do
          video_encoding.fail
          video_encoding.panda_encoding_id.should be_nil
          Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :status => 'processing' })
          VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
          video_encoding.panda_encoding_id.should == id
          video_encoding.should be_encoding
        end
        
        it "transition [:pending, :failed, :active] => :failed (else)" do
          Transcoder.should_receive(:post).with(:encoding, params).and_return({ :id => id, :status => 'failed' })
          VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
          video_encoding.panda_encoding_id.should == id
          video_encoding.should be_failed
        end
      end
    end
    
    describe "event(:activate) { transition :encoding => :active }" do
      let(:video_encoding) { Factory(:video_encoding, :panda_encoding_id => 'ab6be8bb1bcf506842264304bc1bb479', :state => 'encoding') }
      
      it "should set the state as :active from :encoding" do
        video_encoding.should be_encoding
        VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
        video_encoding.should be_active
      end
      
      describe "conditions" do
        it "transition :encoding => :active, :if => :panda_encoding_complete?" do
          VCR.use_cassette('video_encoding/fake_activate') { video_encoding.activate }
          video_encoding.file_size.should be_present
          video_encoding.started_encoding_at.should be_present
          video_encoding.encoding_time.should be_present
          video_encoding.should be_encoding
        end
        
        describe "before_transition => #populate_information" do
          it "should populate video encoding information" do
            video_encoding.stub!(:set_file => true, :set_video_thumbnail => true, :delete_panda_encoding => true)
            VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
            video_encoding.file_size.should be_present
            video_encoding.started_encoding_at.should be_present
            video_encoding.encoding_time.should be_present
            video_encoding.should be_active
          end
        end
      end
      
      describe "callbacks" do
        it "before_transition => #set_file should set file to the encoding's file" do
          video_encoding.stub!(:populate_information => true, :set_video_thumbnail => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.file.url.should == "/uploads/videos/#{video_encoding.video.token}/#{video_encoding.video.name}#{video_encoding.profile.name}#{video_encoding.extname}"
        end
        
        it "before_transition => #set_video_thumbnail should set video thumbnail if profile is thumbnailable" do
          video_encoding.stub!(:populate_information => true, :set_file => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
          video_encoding.profile.stub!(:thumbnailable? => true)
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.video.thumbnail.url.should == "/uploads/videos/#{video_encoding.video.token}/posterframe.jpg"
        end
        
        it "before_transition => #set_video_thumbnail should not set video thumbnail if profile is not thumbnailable" do
          video_encoding.stub!(:populate_information => true, :set_file => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.video.thumbnail.url.should be_nil
        end
        
        it "before_transition => #deprecate_active_encodings should deprecate all the active encodings" do
          video_encoding.stub!(:populate_information => true, :set_file => true, :set_video_thumbnail => true, :delete_panda_encoding => true)
          active_video_encoding = Factory(:video_encoding, :video => video_encoding.video, :profile_version => video_encoding.profile_version, :panda_encoding_id => 'ab6be8bb1bcf506842264304bc1bb479', :state => 'active')
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.should be_active
          active_video_encoding.reload.should be_deprecated
        end
        
        it "after_transition => #delete_panda_encoding should remove the Panda's encoding" do
          video_encoding.stub!(:populate_information => true, :set_file => true, :set_video_thumbnail => true, :deprecate_active_encodings => true)
          VCR.use_cassette('video_encoding/activate') do
            video_encoding.activate
            @response = Transcoder.get(:encoding, "#{video_encoding.panda_encoding_id}d")
          end
          @response[:error].should == "RecordNotFound"
          @response[:message].should == "Couldn't find Encoding with ID=#{video_encoding.panda_encoding_id}d"
        end
        
        it "after_transition => #reflect_video_state should suspend the encoding if video is suspended" do
          video_encoding.stub!(:populate_information => true, :set_file => true, :set_video_thumbnail => true, :deprecate_active_encodings => true, :delete_panda_encoding => true)
          video_encoding.video.suspend
          video_encoding.video.should be_suspended
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.should be_suspended
        end
      end
    end
    
    describe "event(:fail) { transition [:pending, :encoding] => :failed }" do
      it "should set the state as :failed from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        video_encoding.fail
        video_encoding.should be_failed
      end
      
      it "should set the state as :failed from :encoding" do
        video_encoding = Factory(:video_encoding, :state => 'encoding')
        video_encoding.should be_encoding
        video_encoding.fail
        video_encoding.should be_failed
      end
    end
    
    describe "event(:deprecate) { transition [:active, :failed] => :deprecated }" do
      it "should set the state as :deprecated from :active" do
        video_encoding = Factory(:video_encoding, :state => 'active')
        video_encoding.should be_active
        video_encoding.deprecate
        video_encoding.should be_deprecated
      end
      
      it "should set the state as :deprecated from :failed" do
        video_encoding = Factory(:video_encoding, :state => 'failed')
        video_encoding.should be_failed
        video_encoding.deprecate
        video_encoding.should be_deprecated
      end
    end
    
    describe "event(:suspend) { transition :active => :suspended }" do
      let(:video_encoding) { Factory(:video_encoding, :state => 'active') }
      
      it "should set the state as :suspended from :active" do
        video_encoding.should be_active
        VCR.use_cassette('video_encoding/suspend') { video_encoding.suspend }
        video_encoding.should be_suspended
      end
      
      describe "callbacks" do
        it "before_transition => #block_video should set the READ right to NOBODY (or OWNER if it's enough)" do
          
        end
        
        it "after_transition => #purge_video should purge the video file from the cdn" do
          VoxcastCDN.should_receive(:purge).with("/v/#{video_encoding.video.token}/#{video_encoding.video.name}#{video_encoding.profile.name}#{video_encoding.extname}")
          VCR.use_cassette('video_encoding/suspend') { video_encoding.suspend }
        end
      end
    end
    
    describe "event(:unsuspend) { transition :suspended => :active }" do
      let(:video_encoding) { Factory(:video_encoding, :state => 'suspended') }
      
      it "should set the state as :active from :suspended" do
        video_encoding.should be_suspended
        VCR.use_cassette('video_encoding/suspend') { video_encoding.unsuspend }
        video_encoding.should be_active
      end
      
      describe "callbacks" do
        it "before_transition => #unblock_video should set the READ right to WORLD" do
          
        end
      end
    end
    
    describe "event(:archive) { transition [:pending, :encoding, :failed, :active] => :archived }" do
      
      it "should set the state as :deprecated from :pending" do
        video_encoding = Factory(:video_encoding, :state => 'pending')
        video_encoding.should be_pending
        VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :encoding" do
        video_encoding = Factory(:video_encoding, :state => 'encoding')
        video_encoding.should be_encoding
        VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :failed" do
        video_encoding = Factory(:video_encoding, :state => 'failed')
        video_encoding.should be_failed
        VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
        video_encoding.should be_archived
      end
      
      it "should set the state as :deprecated from :active" do
        video_encoding = Factory(:video_encoding, :state => 'active')
        video_encoding.should be_active
        VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
        video_encoding.should be_archived
      end
      
      describe "callbacks" do
        it "before_transition => #remove_file! should delete the video file from S3" do
          video_encoding = Factory(:video_encoding, :panda_encoding_id => 'ab6be8bb1bcf506842264304bc1bb479', :state => 'encoding')
          VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
          video_encoding.file.should be_present
          video_encoding.stub!(:purge_video => true)
          VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
          video_encoding.file.should_not be_present
        end
        
        it "after_transition => #purge_video should purge the video file from the cdn" do
          video_encoding = Factory(:video_encoding, :state => 'active')
          video_encoding.stub!(:remove_file! => true)
          VoxcastCDN.should_receive(:purge).with("/v/#{video_encoding.video.token}/#{video_encoding.video.name}#{video_encoding.profile.name}#{video_encoding.extname}")
          VCR.use_cassette('video_encoding/archive') { video_encoding.archive }
        end
      end
    end
  end
  
  describe "Class Methods" do
    describe ".panda_s3_url" do
      it "should be get from Panda" do
        VCR.use_cassette('video_encoding/class_methods') do
          VideoEncoding.panda_s3_url.should == "http://s3.amazonaws.com/sublimevideo.panda"
        end
      end
    end
  end
  
  describe "Instance Methods" do
    let(:video_encoding) { Factory(:video_encoding, :panda_encoding_id => 'ab6be8bb1bcf506842264304bc1bb479', :state => 'encoding') }
    
    describe "#type" do
      it "should return 'ext' if profile.extname == '.ext'" do
        video_encoding.type.should == 'mp4'
      end
    end
    
    describe "#first_encoding?" do
      let(:video_encoding) { Factory(:video_encoding, :profile_version => Factory(:video_profile_version, :panda_profile_id => '73f93e74e866d86624a8718d21d06e4e')) }
      
      it "should be true if file is not present and state is encoding" do
        VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
        video_encoding.should be_first_encoding
      end
      
      it "should be false if file is already present and state is encoding" do
        VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
        VCR.use_cassette('video_encoding/activate') { video_encoding.activate }
        VCR.use_cassette('video_encoding/pandize') { video_encoding.pandize }
        video_encoding.should_not be_first_encoding
      end
    end
  end
  
end