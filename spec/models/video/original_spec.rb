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

describe Video::Original do
  
  context "built with valid attributes" do
    subject { Factory.build(:video_original) }
    
    its(:panda_id)    { should be_present           }
    its(:user)        { should be_present           }
    its(:original_id) { should be_nil               }
    its(:name)        { should be_nil               }
    its(:token)       { should be_nil               }
    its(:file)        { should be_present           }
    its(:type)        { should == 'Video::Original' }
    
    it { should be_pending }
    it { should be_valid   }
  end
  
  context "created with valid attributes" do
    before(:each) { VCR.insert_cassette('video_original') }
    
    subject { Factory(:video_original) }
    
    its(:name)  { should == "Railscast Intro" }
    its(:token) { should =~ /^[a-z0-9]{8}$/   }
    
    it "should encode after create" do
      subject # trigger video creation
      subject.reload
      subject.formats.size.should == Video.profiles.size
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Validations" do
    it "should validate presence of [:user] on build" do
      video = Factory.build(:video_original, :user => nil)
      video.should_not be_valid
      video.errors[:user].should be_present
    end
  end
  
  describe "State Machine" do
    before(:each) do
      VCR.insert_cassette('video_original')
      @original = Factory(:video_original)
    end
    
    it "deactivate should deactivate each formats as well" do
      @original.should be_pending
      @original.formats.each do |f|
        f.activate
        f.reload
        f.should be_active
      end
      @original.reload
      @original.should be_active
      
      @original.deactivate
      @original.should be_pending
      @original.formats.each { |f| f.should be_pending }
    end
    
    it "should populate formats information after activate" do
      @original.should be_pending
      @original.formats.each do |f|
        f.size.should == 0
        f.activate
        f.reload
        f.should be_active
      end
      @original.reload
      @original.should be_active
      
      @original.formats.each do |f|
        f.size.should be_present
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Callbacks" do
    describe "before_create" do
      describe "#set_infos" do
        before(:each) do
          VCR.insert_cassette('video_original')
          @video = Factory(:video_original)
        end
        
        it "should set infos" do
          @video.name.should      == "Railscast Intro"
          @video.codec.should     be_present
          @video.container.should be_present
          @video.size.should      be_present
          @video.duration.should  be_present
          @video.width.should     be_present
          @video.height.should    be_present
          @video.state.should     be_present
        end
        
        after(:each) { VCR.eject_cassette }
      end
    end
  end
  
  describe "Instance Methods" do
    describe "#total_size" do
      it "should return total storage (original size + formats sizes)" do
        VCR.use_cassette('video_original') do
          original = Factory(:video_original)
          
          original.total_size.should == original.size + original.formats.map(&:size).sum
        end
      end
    end
    
    describe "#all_formats_active" do
      it "should return true if all the formats of a original video are active" do
        VCR.use_cassette('video_original') do
          original = Factory(:video_original)
          original.all_formats_active?.should be_false
          
          original.formats.each do |f|
            f.activate
            f.reload
            f.should be_active
          end
          original.all_formats_active?.should be_true
        end
      end
    end
  end
  
end
