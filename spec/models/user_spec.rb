# == Schema Information
#
# Table name: users
#
#  id                                    :integer         not null, primary key
#  state                                 :string(255)
#  email                                 :string(255)     default(""), not null
#  encrypted_password                    :string(128)     default(""), not null
#  password_salt                         :string(255)     default(""), not null
#  full_name                             :string(255)
#  confirmation_token                    :string(255)
#  confirmed_at                          :datetime
#  confirmation_sent_at                  :datetime
#  reset_password_token                  :string(255)
#  remember_token                        :string(255)
#  remember_created_at                   :datetime
#  sign_in_count                         :integer         default(0)
#  current_sign_in_at                    :datetime
#  last_sign_in_at                       :datetime
#  current_sign_in_ip                    :string(255)
#  last_sign_in_ip                       :string(255)
#  failed_attempts                       :integer         default(0)
#  locked_at                             :datetime
#  invoices_count                        :integer         default(0)
#  last_invoiced_on                      :date
#  next_invoiced_on                      :date
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#  limit_alert_amount                    :integer         default(0)
#  limit_alert_email_sent_at             :datetime
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expire_on                          :date
#  cc_updated_at                         :datetime
#  created_at                            :datetime
#  updated_at                            :datetime
#

require 'spec_helper'

describe User do
  
  context "with valid attributes" do
    subject { Factory(:user) }
    
    its(:full_name)        { should == "Joe Blow" }
    its(:email)            { should match /email\d+@user.com/ }
    its(:invoices_count)   { should == 0 }
    its(:last_invoiced_on) { should be_nil }
    its(:next_invoiced_on) { should == Time.now.utc.to_date + 1.month }
    it { should be_valid }
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
  end
  
end
