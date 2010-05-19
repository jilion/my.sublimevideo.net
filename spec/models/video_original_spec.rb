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

describe VideoOriginal do
  context "with valid attributes" do
    subject { Factory(:video_original) }
    
    it { subject.type               == 'VideoOriginal' }
    it { subject.token.should       =~ /^[a-z0-9]{8}$/ }
    it { subject.file.should        be_present         }
    it { subject.user.should        be_present         }
    it { subject.original_id.should be_nil             }
    it { subject.should             be_valid           }
  end
  
  describe "Validates" do
    it "should validate presence of [:user] on build" do
      video = Factory.build(:video_original, :user => nil)
      video.should_not be_valid
      video.errors[:user].should be_present
    end
  end
  
  describe "Callbacks" do
    describe "before_create" do
      describe "#set_name" do
        it "should set video name after save if file is present and file has changed or video is a new record" do
          Factory(:video_original).name.should == "Image"
        end
      end
    end
  end
  
  describe "Instance Methods" do
    describe "#set_name" do
      it "should set video name from filename" do
        video = Factory(:video_original)
        video.set_name
        video.name.should == "Image"
      end
    end
    
    describe "#total_size" do
      it "should return total storage (original size + formats sizes)" do
        original = Factory(:video_original)
        format = Factory(:video_format, :original => original)
        original.total_size.should == 200_000_000
      end
    end
  end
end
