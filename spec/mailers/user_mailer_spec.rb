require 'spec_helper'

describe UserMailer do
  subject { Factory(:user) }
  
  it_should_behave_like "common mailer checks", %w[account_suspended account_unsuspended], :params => [Factory(:user)]
  
  describe "#account_suspended" do
    context "when reason given is :invoice_problem" do
      before(:each) do
        UserMailer.account_suspended(subject).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end
      
      it "should set proper subject" do
        @last_delivery.subject.should == "Your account has been suspended"
      end
      
      it "should set a body that contain infos" do
        @last_delivery.body.encoded.should include "your account has been suspended!"
      end
    end
  end
  
  describe "#account_unsuspended" do
    before(:each) do
      UserMailer.account_unsuspended(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set proper subject" do
      @last_delivery.subject.should == "Your account has been un-suspended"
    end
    
    it "should set a body that contain infos" do
      @last_delivery.body.encoded.should include "your account has been un-suspended!"
    end
  end
  
end