require 'spec_helper'

describe User do
  
  # should_allow_mass_assignment_of     :full_name, :email, :password, :password_confirmation
  # should_not_allow_mass_assignment_of :id, :created_at, :updated_at
  
  describe "with valid attributes" do
    before :each do
      @subject = Factory(:user)
    end
    
    it "should be a valid factory" do
      @subject.full_name.should == "Joe Blow"
      @subject.email.should match /email\d+@user.com/
      @subject.should be_valid
    end
  end
  
  describe "scopes" do
  end
  
  # should_have_many :sites
  # should_have_many :videos
  # should_validate_presence_of :full_name
  
  describe "instance methods" do
  end
  
end