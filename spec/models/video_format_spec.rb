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

describe VideoFormat do
  context "with valid attributes" do
    subject { Factory(:video_format) }
    
    it { subject.type            == 'VideoFormat'   }
    it { subject.token.should    =~ /^[a-z0-9]{8}$/ }
    it { subject.file.should     be_present         }
    it { subject.user_id.should  be_nil             }
    it { subject.original.should be_present         }
    it { subject.should          be_valid           }
  end
  
  describe "Validates" do
    it "should validate presence of [:original]" do
      video = Factory.build(:video_format, :original => nil)
      video.should_not be_valid
      video.errors[:original].should be_present
    end
    
    it "should validate presence of [:name]" do
      video = Factory.build(:video_format, :name => nil)
      video.should_not be_valid
      video.errors[:name].should be_present
    end
  end
  
end
