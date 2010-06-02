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
require 'carrierwave/test/matchers'

# TODO VCRize all this
describe Video do
  FACTORIES = %w[video_original video_format]
  
  pending "base instance behaviour" do
    before(:all) do
      VCR.use_cassette('videos/video_upload') do
        # fake video upload, just to get the panda_id
        @panda_id = JSON[Panda.post("/videos.json", :file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"))]['id']
      end
    end
    
    before(:each) { VCR.insert_cassette('videos/one_saved_video') }
    
    describe "Validations" do
      FACTORIES.each do |factory|
        it "should validate presence of [:type] on build of #{factory}" do
          video = Factory.build(factory, :type => nil)
          video.should_not be_valid
          video.errors[:type].should be_present
        end
      end
      
      FACTORIES.each do |factory|
        it "should validate inclusion of type in %w[VideoOriginal VideoFormat] on build of #{factory}" do
          video = Factory.build(factory)
          video.type.should be_present
          video.should be_valid
          video.errors[:type].should be_empty
        
          video = Factory.build(factory, :type => 'foo')
          video.should_not be_valid
          video.errors[:type].should be_present
        end
      end
      
      FACTORIES.each do |factory|
        it "should validate presence of [:panda_id] on build of #{factory}" do
          video = Factory.build(factory, :panda_id => nil)
          video.should_not be_valid
          video.errors[:panda_id].should be_present
        end
      end
    end
    
    describe "State Machine" do
      FACTORIES.each do |factory|
        it "#{factory} should be initially pending" do
          video = Factory.build(factory)
          video.should be_pending
        end
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  # pending examples because size and duration will be setted from the real file, so can't test now
  pending "Callbacks" do
    describe "before_create" do
      describe "#set_infos" do
        let(:video) { Factory(:video_original) }
        
        it "should set video name" do
          video.name.should be_present
        end
        
        it "should set video name to Untitled - %m/%d/%Y %I:%M%p if name is blank" do
          video = Factory(:video_original)
          video.stub_chain(:file, :url).and_return(' _ ')
          video.set_name
          video.name.should =~ %r(^Untitled - \d{2}/\d{2}/\d{4} \d{2}:\d{2}[AP]M$)
        end
        
        it "should set video codec" do
          video.codec.should be_present
        end
        
        it "should set video container" do
          video.container.should be_present
        end
        
        it "should set video size" do
          video.size.should be_present
        end
        
        it "should set video duration" do
          video.duration.should be_present
        end
        
        it "should set video width" do
          video.width.should be_present
        end
        
        it "should set video height" do
          video.height.should be_present
        end
        
        # @state     = video_infos[:status] == 'success' ? 'active' : video_infos[:status]
        it "should set video state" do
          video.state.should be_present
        end
        
      end
    end
  end
  
  describe "Class Methods" do
  end
  
  pending "Instance Methods" do
    describe "#set_name" do
      it "should set video name from filename" do
        video = Factory(:video_original)
        video.set_name
        video.name.should == "Railscast Intro"
      end
      
      it "should set video name to Untitled - %m/%d/%Y %I:%M%p if name is blank" do
        video = Factory(:video_original)
        video.stub_chain(:file, :url).and_return(' _ ')
        video.set_name
        video.name.should =~ %r(^Untitled - \d{2}/\d{2}/\d{4} \d{2}:\d{2}[AP]M$)
      end
    end
  end
  
end
