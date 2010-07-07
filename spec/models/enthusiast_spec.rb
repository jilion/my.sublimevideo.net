# == Schema Information
#
# Table name: enthusiasts
#
#  id         :integer         not null, primary key
#  email      :string(255)
#  free_text  :text
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Enthusiast do
  
  context "with valid attributes" do
    subject { Factory(:enthusiast) }
    
    its(:email)            { should match /email\d+@enthusiast.com/ }
    it { should be_valid }
  end
  
  describe "validates" do
    it "should validate presence of email" do
      enthusiast = Factory.build(:enthusiast, :email => nil)
      enthusiast.should_not be_valid
      enthusiast.should have(1).error_on(:email)
    end
    
    context "with already the email in db" do
      before(:each) { @enthusiast = Factory(:enthusiast) }
      
      it "should validate uniqueness of email" do
        enthusiast = Factory.build(:enthusiast, :email => @enthusiast.email)
        enthusiast.should_not be_valid
        enthusiast.should have(1).error_on(:email)
      end
    end
  end
  
end