# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  name        :string(255)
#  token       :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  size        :integer
#  duration    :integer
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
    
    it "activate should set video name" do
    end
    
  end
  
  describe "Callbacks" do
    describe "before_create" do
      describe "#set_size" do
        it "should set video size after save if file is present and file has changed or video is a new record" do
          FACTORIES.each do |factory|
            Factory(factory).size.should == 100_000_000
          end
        end
      end
      
      describe "#set_duration" do
        it "should set video duration after save if file is present and file has changed or video is a new record" do
          FACTORIES.each do |factory|
            Factory(factory).duration.should == 300
          end
        end
      end
    end
  end
    
  describe "Instance Methods" do
    
    it "should set video size" do
      FACTORIES.each do |factory|
        video = Factory(factory)
        video.set_size
        video.size.should == 100_000_000
      end
    end
    
    it "should set video duration" do
      FACTORIES.each do |factory|
        video = Factory(factory)
        video.set_duration
        video.duration.should == 300
      end
    end
    
  end
  
end
