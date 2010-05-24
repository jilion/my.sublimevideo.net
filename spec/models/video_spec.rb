# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  panda_id    :string(255)
#  user_id     :integer
#  original_id :integer
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
  
  describe "Validates" do
    it "should validate presence of [:type] on build" do
      FACTORIES.each do |factory|
        video = Factory.build(factory, :type => nil)
        video.should_not be_valid
        video.errors[:type].should be_present
      end
    end
    
    it "should validate inclusion of type in %w[VideoOriginal VideoFormat]" do
      FACTORIES.each do |factory|
        video = Factory.build(factory)
        video.should be_valid
        video.errors[:type].should be_empty
        
        video = Factory.build(factory, :type => 'foo')
        video.should_not be_valid
        video.errors[:type].should be_present
      end
    end
  end
  
  describe "State Machine" do
  end
  
  # pending examples because size and duration will be setted from the real file, so can't test now
  describe "Callbacks" do
    describe "before_create" do
      describe "#set_size" do
        pending "should set video size after save if file is present and file has changed or video is a new record" do
          FACTORIES.each do |factory|
            Factory(factory).size.should == 5
          end
        end
      end
    end
  end
  
  describe "Class Methods" do
    it "should return panda profiles ids as 'id1, id2'" do
      Video.panda_profiles_ids.should =~ /(\w,)*\w+/
    end
  end
  
  describe "Instance Methods" do
    pending "should set video size" do
      FACTORIES.each do |factory|
        video = Factory(factory)
        video.set_size
        video.size.should == 5
      end
    end
  end
  
end
