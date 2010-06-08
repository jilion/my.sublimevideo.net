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

describe Video::Format do
  
  context "built with valid attributes" do
    before(:each) { VCR.insert_cassette('video_format') }
    
    subject { Factory(:video_original).formats.first }
    
    its(:panda_id) { should be_present            }
    its(:original) { should be_present            }
    its(:name)     { should == 'iphone-handbrake' }
    its(:token)    { should =~ /^[a-z0-9]{8}$/    }
    its(:file)     { should be_blank              }
    its(:type)     { should == 'Video::Format'    }
    its(:errors)   { should be_empty              }
    
    it { should be_pending }
    it { should be_valid   }
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Validations" do
    before(:each) { VCR.insert_cassette('video_format') }
    
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
  
  describe "Class Methods" do
    describe ".create_with_encoding_response(original, encoding_response)" do
      it "should create a format from an original and a hash of information (returned by a post request to panda)" do
        VCR.use_cassette('video_format') do
          original = Factory(:video_original)
          encoding_response = JSON[Panda.post("/encodings.json", { :video_id => original.panda_id, :profile_id => '7bb7560ba8f7657dc0d6d71fc98693c4' })]
          encoding_response['title'] = 'iPhone'
          format = Video::Format.create_with_encoding_response(original, encoding_response)
          
          format.name.should == 'iPhone'
          format.should be_valid
          format.original.should == original
          original.formats.should include format
        end
      end
    end
  end
  
end
