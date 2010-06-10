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

describe Video do
  
  # describe "base instance behaviour" do
  #   before(:each) { VCR.insert_cassette('video') }
  #   
  #   describe "Validations" do
  #     FACTORIES.each do |factory|
  #       it "should validate presence of [:type] on build of #{factory}" do
  #         video = Factory.build(factory, :type => nil)
  #         video.should_not be_valid
  #         video.errors[:type].should be_present
  #       end
  #     end
  #     
  #     FACTORIES.each do |factory|
  #       it "should validate inclusion of type in %w[Video::Original Video::Format] on build of #{factory}" do
  #         video = Factory.build(factory, :type => 'foo')
  #         video.should_not be_valid
  #         video.errors[:type].should be_present
  #       end
  #     end
  #     
  #     FACTORIES.each do |factory|
  #       it "should validate presence of [:panda_id] on build of #{factory}" do
  #         video = Factory.build(factory, :panda_id => nil)
  #         video.should_not be_valid
  #         video.errors[:panda_id].should be_present
  #       end
  #     end
  #   end
  #   
  #   after(:each) { VCR.eject_cassette }
  # end
  # 
  # describe "Class Methods" do
  #   describe ".profiles" do
  #     it "should return the current profiles we have in Panda" do
  #       VCR.use_cassette('video') do
  #         Video.profiles.should == Panda.get("/profiles.json")
  #       end
  #     end
  #   end
  # end
  
  # context "built with valid attributes" do
  #   subject { Factory.build(:video) }
  #   
  #   its(:panda_id)    { should be_present           }
  #   its(:user)        { should be_present           }
  #   its(:original_id) { should be_nil               }
  #   its(:name)        { should be_nil               }
  #   its(:token)       { should be_nil               }
  #   its(:file)        { should be_present           }
  #   its(:type)        { should == 'Video::Original' }
  #   
  #   it { should be_pending }
  #   it { should be_valid   }
  # end
  # 
  # context "created with valid attributes" do
  #   before(:each) { VCR.insert_cassette('video') }
  #   
  #   subject { Factory(:video) }
  #   
  #   its(:name)  { should == "Railscast Intro" }
  #   its(:token) { should =~ /^[a-z0-9]{8}$/   }
  #   
  #   it "should encode after create" do
  #     subject # trigger video creation
  #     subject.reload
  #     subject.formats.size.should == Video.profiles.size
  #   end
  #   
  #   after(:each) { VCR.eject_cassette }
  # end
  # 
  # describe "Validations" do
  #   it "should validate presence of [:user] on build" do
  #     video = Factory.build(:video, :user => nil)
  #     video.should_not be_valid
  #     video.errors[:user].should be_present
  #   end
  # end
  # 
  # describe "State Machine" do
  #   before(:each) do
  #     VCR.insert_cassette('video')
  #     @original = Factory(:video)
  #   end
  #   
  #   it "deactivate should deactivate each formats as well" do
  #     @original.should be_pending
  #     @original.formats.each do |f|
  #       f.activate
  #       f.reload
  #       f.should be_active
  #     end
  #     @original.reload
  #     @original.should be_active
  #     
  #     @original.deactivate
  #     @original.should be_inactive
  #     @original.formats.each { |f| f.should be_inactive }
  #   end
  #   
  #   it "should populate formats information after activate" do
  #     @original.should be_pending
  #     @original.formats.each do |f|
  #       f.size.should == 0
  #       f.activate
  #       f.reload
  #       f.should be_active
  #     end
  #     @original.reload
  #     @original.should be_active
  #     
  #     @original.formats.each do |f|
  #       f.size.should be_present
  #     end
  #   end
  #   
  #   after(:each) { VCR.eject_cassette }
  # end
  # 
  # describe "Callbacks" do
  #   describe "before_create" do
  #     describe "#set_infos" do
  #       before(:each) do
  #         VCR.insert_cassette('video')
  #         @video = Factory(:video)
  #       end
  #       
  #       it "should set infos" do
  #         @video.name.should      == "Railscast Intro"
  #         @video.codec.should     be_present
  #         @video.extname.should be_present
  #         @video.size.should      be_present
  #         @video.duration.should  be_present
  #         @video.width.should     be_present
  #         @video.height.should    be_present
  #         @video.state.should     be_present
  #       end
  #       
  #       after(:each) { VCR.eject_cassette }
  #     end
  #   end
  # end
  # 
  # describe "Instance Methods" do
  #   describe "#total_size" do
  #     it "should return total storage (original size + formats sizes)" do
  #       VCR.use_cassette('video') do
  #         original = Factory(:video)
  #         
  #         original.total_size.should == original.size + original.formats.map(&:size).sum
  #       end
  #     end
  #   end
  #   
  #   describe "#all_formats_active" do
  #     it "should return true if all the formats of a original video are active" do
  #       VCR.use_cassette('video') do
  #         original = Factory(:video)
  #         original.all_formats_active?.should be_false
  #         
  #         original.formats.each do |f|
  #           f.activate
  #           f.reload
  #           f.should be_active
  #         end
  #         original.all_formats_active?.should be_true
  #       end
  #     end
  #   end
  # end
  
end