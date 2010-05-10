# == Schema Information
#
# Table name: users
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  password_salt        :string(255)     default(""), not null
#  full_name            :string(255)
#  confirmation_token   :string(255)
#  confirmed_at         :datetime
#  confirmation_sent_at :datetime
#  reset_password_token :string(255)
#  remember_token       :string(255)
#  remember_created_at  :datetime
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  failed_attempts      :integer         default(0)
#  locked_at            :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe User do
  
  # should_allow_mass_assignment_of     :full_name, :email, :password, :password_confirmation
  # should_not_allow_mass_assignment_of :id, :created_at, :updated_at
  
  # describe "with valid attributes" do
  #   before :each do
  #     @subject = Factory(:user)
  #   end
  #   
  #   it "should be a valid factory" do
  #     @subject.full_name.should == "Joe Blow"
  #     @subject.email.should match /email\d+@user.com/
  #     @subject.should be_valid
  #   end
  # end
  context "with valid attributes" do
    subject { Factory(:user) }
    
    it { subject.full_name.should == "Joe Blow" }
    it { subject.email.should match /email\d+@user.com/ }
    it { subject.should be_valid }
  end
  
  describe "scopes" do
  end
  
  # should_have_many :sites
  # should_have_many :videos
  # should_validate_presence_of :full_name
  
  describe "instance methods" do
  end
  
end
