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

# TODO VCRize all this
describe VideoFormat do
  
  before(:all) do
    # fake video upload, just to get the panda_id
    @panda_id = 'f72e511820c12dabc1d15817745225bd'
  end
  
  pending "built with valid attributes" do
    before(:each) { VCR.insert_cassette('videos/one_saved_video') }
    
    subject { Factory.build(:video_format, :panda_id => @panda_id) }
    
    it { subject.panda_id.should    be_present         }
    it { subject.user.should        be_nil             }
    it { subject.original_id.should be_present         }
    it { subject.name.should        be_nil             }
    it { subject.token.should       be_nil             }
    it { subject.file.should        be_present         }
    it { subject.type               == 'VideoFormat'   }
    it { subject.should             be_pending         }
    it { subject.should             be_valid           }
    
    after(:each) { VCR.eject_cassette }
  end
  
  pending "Validations" do
    before(:each) { VCR.insert_cassette('videos/one_saved_video') }
    
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
    
    after(:each) { VCR.eject_cassette }
  end
  
end
