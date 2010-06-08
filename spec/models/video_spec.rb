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

describe Video do
  FACTORIES = %w[video_original video_format]
  
  describe "base instance behaviour" do
    before(:each) { VCR.insert_cassette('video') }
    
    describe "Validations" do
      FACTORIES.each do |factory|
        it "should validate presence of [:type] on build of #{factory}" do
          video = Factory.build(factory, :type => nil)
          video.should_not be_valid
          video.errors[:type].should be_present
        end
      end
      
      FACTORIES.each do |factory|
        it "should validate inclusion of type in %w[Video::Original Video::Format] on build of #{factory}" do
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
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Class Methods" do
    describe ".profiles" do
      it "should return the current profiles we have in Panda" do
        VCR.use_cassette('multi_video_profiles') do
          Video.profiles.should == JSON[Panda.get("/profiles.json")]
        end
      end
    end
  end
  
end
