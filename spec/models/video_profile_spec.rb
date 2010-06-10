# == Schema Information
#
# Table name: video_profiles
#
#  id                :integer         not null, primary key
#  title             :string(255)
#  description       :text
#  name              :string(255)
#  extname           :string(255)
#  thumbnailable     :boolean
#  active_version_id :integer
#  versions_count    :integer         default(0)
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe VideoProfile do
  
  context "built with valid attributes" do
    subject { Factory.build(:video_profile) }
    
    its(:title)   { should be_present }
    its(:name)    { should be_present }
    its(:extname) { should be_present }
    
    it { should be_valid }
  end
  
  describe "Validations" do
    it "should validate presence of [:title] on build" do
      video_profile = Factory.build(:video_profile, :title => nil)
      video_profile.should_not be_valid
      video_profile.errors[:title].should be_present
    end
    it "should validate presence of [:extname] on build" do
      video_profile = Factory.build(:video_profile, :extname => nil)
      video_profile.should_not be_valid
      video_profile.errors[:extname].should be_present
    end
  end
  
  describe "State Machine" do
  end
  
  describe "Callbacks" do
    describe "before_create" do
      it "should set thumbnailable to false if not specified" do
        vp = Factory(:video_profile)
        vp.should be_valid
        vp.thumbnailable.should be_false
      end
      it "should not set thumbnailable to false if specified" do
        vp = Factory(:video_profile, :thumbnailable => true)
        vp.thumbnailable.should be_true
      end
    end
  end
  
  # describe "Class Methods" do
  #   describe ".active_panda_profiles_ids" do
  #     it "should return all the active profiles" do
  #       vp1   = Factory(:video_profile)
  #       vpv11 = Factory(:video_profile_version, :profile => vp1, :panda_profile_id => '11')
  #       vp1.versions << Factory(:video_profile_version, :panda_profile_id => '12')
  #       vp1.active_version = vpv11
  #       vp1.save
  #       
  #       vp2   = Factory(:video_profile)
  #       vp2.versions << Factory(:video_profile_version, :panda_profile_id => '21')
  #       vpv22 = Factory(:video_profile_version, :profile => vp2, :panda_profile_id => '22')
  #       vp2.active_version = vpv22
  #       vp2.save
  #       
  #       VideoProfile.active_panda_profiles_ids.should == ['11', '22']
  #     end
  #   end
  # end
  
  describe "Instance Methods" do
  end
  
end