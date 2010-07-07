# == Schema Information
#
# Table name: admins
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  password_salt        :string(255)     default(""), not null
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
#  invitation_token     :string(20)
#  invitation_sent_at   :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe Admin do
  
  context "with valid attributes" do
    subject { Factory(:admin) }
    
    its(:email)            { should match /email\d+@admin.com/ }
    it { should be_valid }
  end
  
  describe "validates" do
    it "should validate presence of email" do
      admin = Factory.build(:admin, :email => nil)
      admin.should_not be_valid
      admin.should have(1).error_on(:email)
    end
    
    context "with already a site in db" do
      before(:each) { @admin = Factory(:admin) }
      
      it "should validate uniqueness of email" do
        admin = Factory.build(:admin, :email => @admin.email)
        admin.should_not be_valid
        admin.should have(1).error_on(:email)
      end
    end
  end
  
end