# == Schema Information
#
# Table name: video_encodings
#
#  id                       :integer         not null, primary key
#  video_id                 :integer
#  video_profile_id         :integer
#  video_profile_version_id :integer
#  state                    :string(255)
#  file                     :string(255)
#  panda_encoding_id        :integer
#  started_encoding_at      :datetime
#  encoding_time            :integer
#  extname                  :string(255)
#  file_size                :integer
#  width                    :integer
#  height                   :integer
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe VideoEncoding do
  
  # context "built with valid attributes" do
  #   before(:each) { VCR.insert_cassette('video_encoding') }
  #   
  #   subject { Factory(:video).formats.first }
  #   
  #   its(:panda_id) { should be_present            }
  #   its(:original) { should be_present            }
  #   its(:name)     { should == 'iphone-handbrake' }
  #   its(:token)    { should =~ /^[a-z0-9]{8}$/    }
  #   its(:file)     { should be_blank              }
  #   its(:type)     { should == 'Video::Format'    }
  #   its(:errors)   { should be_empty              }
  #   
  #   it { should be_pending }
  #   it { should be_valid   }
  #   
  #   after(:each) { VCR.eject_cassette }
  # end
  # 
  # describe "Validations" do
  #   before(:each) { VCR.insert_cassette('video_encoding') }
  #   
  #   it "should validate presence of [:original]" do
  #     video = Factory.build(:video_encoding, :original => nil)
  #     video.should_not be_valid
  #     video.errors[:original].should be_present
  #   end
  #   
  #   it "should validate presence of [:name]" do
  #     video = Factory.build(:video_encoding, :name => nil)
  #     video.should_not be_valid
  #     video.errors[:name].should be_present
  #   end
  #   
  #   after(:each) { VCR.eject_cassette }
  # end
  # 
  # describe "Class Methods" do
  #   describe ".create_with_encoding_response(original, encoding_response)" do
  #     it "should create a format from an original and a hash of information (returned by a post request to panda)" do
  #       VCR.use_cassette('video_encoding') do
  #         original = Factory(:video)
  #         encoding_response = Panda.post("/encodings.json", { :video_id => original.panda_id, :profile_id => '7bb7560ba8f7657dc0d6d71fc98693c4' })
  #         encoding_response['title'] = 'iPhone'
  #         format = Video::Format.create_with_encoding_response(original, encoding_response)
  #         
  #         format.name.should == 'iPhone'
  #         format.should be_valid
  #         format.original.should == original
  #         original.formats.should include format
  #       end
  #     end
  #   end
  # end
  
end
