# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  name        :string(255)
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

describe VideoFormat do
  context "with valid attributes" do
    subject { Factory.build(:video_format) }
    
    it { subject.type            == 'VideoFormat' }
    it { subject.file.should     be_present       }
    it { subject.user_id.should  be_nil           }
    it { subject.original.should be_present       }
    it { subject.should          be_valid         }
  end
  
  describe "Validates" do
    it "should set video name from filename" do
      video = Factory(:video_format)
      video.set_name
      video.name.should == "iPhone (mp4)"
    end
    
    it "should validate presence of [:original] on build" do
      video = Factory.build(:video_format, :original => nil)
      video.should_not be_valid
      video.errors[:original].should be_present
    end
  end
  
  describe "Callbacks" do
    describe "before_create" do
      describe "#set_name" do
        it "should set video name after save if file is present and file has changed or video is a new record" do
          Factory(:video_format).name.should == "iPhone (mp4)"
        end
      end
    end
  end
  
end
