# == Schema Information
#
# Table name: users
#
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expired_on                         :date
#  cc_updated_at                         :datetime
#

require 'spec_helper'

describe User::CreditCard do
  let(:user) { Factory(:user) }
  
  describe "with valid attributes" do
    before(:each) do
      user.update_attributes(
        :cc_type               => 'visa',
        :cc_number             => '4111111111111111',
        :cc_expired_on         => 1.year.from_now.to_date,
        :cc_first_name         => 'John',
        :cc_last_name          => 'Doe',
        :cc_verification_value => '111'
      )
    end
    
    subject { user }
    
    it { should be_valid }
    it { should be_credit_card }
    it { should be_cc }
    its(:cc_type)         { should == 'visa' }
    its(:cc_last_digits)  { should == 1111 }
    its(:cc_expired_on)   { should == 1.year.from_now.to_date }
    its(:cc_updated_at)   { should be_present }
  end
  
  
  
end
