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
    its(:extname)             { should be_nil     }
    its(:file_size)           { should be_nil     }
    its(:width)               { should be_nil     }
    its(:height)              { should be_nil     }
    
    it { should be_valid   }
  end
  
  describe "Validations" do
    it "should validate presence of :video" do
      video = Factory.build(:video_encoding, :video => nil)
      video.should_not be_valid
      video.errors[:video].should be_present
    end
    
    it "should validate presence of :profile_version" do
      video = Factory.build(:video_encoding, :profile_version => nil)
      video.should_not be_valid
      video.errors[:profile_version].should be_present
    end
  end
  
  describe "State Machine" do
    describe "initial state" do
      before(:each) { @video_encoding = Factory(:video_encoding) }
      
      it "should be pending" do
        @video_encoding.should be_pending
      end
    end
    
    describe "event(:pandize)" do
      before(:each) do
        @video_encoding = Factory(:video_encoding, :profile_version => Factory(:video_profile_version, :panda_profile_id => '73f93e74e866d86624a8718d21d06e4e'))
        @params = { :video_id => @video_encoding.video.panda_video_id, :profile_id => @video_encoding.profile_version.panda_profile_id }
      end
      
      it "transition [:pending, :active] => :encoding, :if => :encoding_ok?" do
        Transcoder.should_receive(:post).with(:encoding, @params).and_return({:id => 'ab6be8bb1bcf506842264304bc1bb479', :status => 'processing'})
        VCR.use_cassette('video_encoding/pandize') { @video_encoding.pandize }
        @video_encoding.panda_encoding_id.should == 'ab6be8bb1bcf506842264304bc1bb479'
        @video_encoding.should be_encoding
      end
      
      it "transition :failed => :encoding,  :if => :retry_encoding_ok?" do
        @video_encoding.fail
        Transcoder.should_receive(:post).with(:encoding, @params).and_return({:id => 'ab6be8bb1bcf506842264304bc1bb479', :status => 'processing'})
        VCR.use_cassette('video_encoding/pandize') { @video_encoding.pandize }
        @video_encoding.panda_encoding_id.should == 'ab6be8bb1bcf506842264304bc1bb479'
        @video_encoding.should be_encoding
      end
      
      it "transition [:pending, :failed, :active] => :failed" do
        Transcoder.should_receive(:post).with(:encoding, @params).and_return({:id => 'ab6be8bb1bcf506842264304bc1bb479', :status => 'failed'})
        VCR.use_cassette('video_encoding/pandize') { @video_encoding.pandize }
        @video_encoding.panda_encoding_id.should == 'ab6be8bb1bcf506842264304bc1bb479'
        @video_encoding.should be_failed
      end
      
      it "transition [:pending, :failed, :active] => :failed" do
        Transcoder.should_receive(:post).with(:encoding, @params).and_return({})
        VCR.use_cassette('video_encoding/pandize') { @video_encoding.pandize }
        @video_encoding.panda_encoding_id.should be_nil
        @video_encoding.should be_failed
      end
    end
    
    describe "event(:activate)" do
      before(:each) do
        @video_encoding = Factory(:video_encoding, :panda_encoding_id => 'ab6be8bb1bcf506842264304bc1bb479', :extname => '.mp4', :state => 'encoding')
      end
      
      describe "before_transition :on => :activate" do
        it ":populate_information should populate video encoding information" do
          @video_encoding.stub!(:set_file => true, :set_video_thumbnail => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
          @video_encoding.file_size.should be_present
          @video_encoding.started_encoding_at.should be_present
          @video_encoding.encoding_time.should be_present
        end
        
        it ":set_file should set file to the encoding's file" do
          @video_encoding.stub!(:populate_information => true, :set_video_thumbnail => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
          @video_encoding.file.url.should == "/uploads/videos/#{@video_encoding.video.token}/#{@video_encoding.video.name}#{@video_encoding.profile.name}#{@video_encoding.extname}"
        end
        
        it ":set_video_thumbnail should set video thumbnail if profile is thumbnailable" do
          @video_encoding.stub!(:populate_information => true, :set_file => true, :delete_panda_encoding => true)
          @video_encoding.profile_version.update_attribute(:profile, Factory(:video_profile, :thumbnailable => true))
          VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
          @video_encoding.video.thumbnail.url.should == "/uploads/videos/#{@video_encoding.video.token}/posterframe.jpg"
        end
        
        it ":set_video_thumbnail should not set video thumbnail if profile is not thumbnailable" do
          @video_encoding.stub!(:populate_information => true, :set_file => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') { @video_encoding.activate }
          @video_encoding.video.thumbnail.url.should be_nil
        end
      end
      
      describe "after_transition  :on => :activate, :do => :delete_panda_encoding" do
        it "should remove the Panda's encoding" do
          @video_encoding.stub!(:populate_information => true, :set_file => true, :set_video_thumbnail => true, :delete_panda_encoding => true)
          VCR.use_cassette('video_encoding/activate') do
            @video_encoding.activate
            @response = Transcoder.get(:encoding, "#{@video_encoding.panda_encoding_id}d")
          end
          @response[:error].should == "RecordNotFound"
          @response[:message].should == "Couldn't find Encoding with ID=#{@video_encoding.panda_encoding_id}d"
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
  
end