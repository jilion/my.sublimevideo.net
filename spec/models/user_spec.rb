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
#  invoices_count       :integer         default(0)
#  last_invoiced_on     :date
#  next_invoiced_on     :date
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe User do
  
  context "with valid attributes" do
    subject { Factory(:user) }
    
    its(:full_name)        { should == "Joe Blow" }
    its(:email)            { should match /email\d+@user.com/ }
    its(:invoices_count)   { should == 0 }
    it { subject.last_invoiced_on. should be_nil } # Wait RSpec fix
    its(:next_invoiced_on) { should == Time.now.utc.to_date + 1.month }
    it { should be_valid }
    it { should be_trial }
  end
  
  describe "validates" do
    it "should validate presence of full_name" do
      user = User.create(:full_name => nil)
      user.errors[:full_name].should be_present
    end
    it "should validate presence of email" do
      user = User.create(:email => nil)
      user.errors[:email].should be_present
    end
    
    context "with already a site in db" do
      before(:each) { @user = Factory(:user) }
      
      it "should validate uniqueness of email" do
        user = User.create(:email => @user.email)
        user.errors[:email].should be_present
      end
    end
  end
  
  describe "scopes" do
  end
  
  describe "instance methods" do
    it "should be welcome if sites is empty" do
      user = Factory(:user)
      user.should be_welcome
    end
    
    it "should be in trial mode" do
      user = Factory(:user)
      Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits)
      user.should be_trial
    end
    
    it "should not be in trial mode" do
      user = Factory(:user)
      Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits + 1)
      user.should_not be_trial
    end
    
    it "should have trial mode usage at 33%" do
      user = Factory(:user)
      Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 3)
      user.trial_usage_percentage.should == 33
    end
    
    it "should have trial mode usage 25%" do
      user = Factory(:user)
      Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 5, :player_hits_cache => Trial.free_player_hits / 4)
      user.trial_usage_percentage.should == 25
    end
  end
  
end
