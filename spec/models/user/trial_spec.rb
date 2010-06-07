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
#  trial_ended_at    :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe Trial do
  let(:user) { Factory(:user) }
  
  context "with trial user" do
    subject { Factory(:user) }
    
    it { should be_trial }
  end
  
  context "with user" do
    subject { Factory(:user, :trial_ended_at => Time.now.utc) }
    
    it { should_not be_trial }
  end
  
  describe "module method" do
    
    describe "supervise_users" do
      
      it "should send info email when user reach 50%" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 2)
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Trial Usage as reach 50%"
        user.reload.trial_usage_information_email_sent_at.should be_present
      end
      
      it "should not send info email when user reach 50% if info email already sent" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 2)
        Trial.supervise_users
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should not send info email when user is not in trial" do
        user = Factory(:user, :trial_ended_at => Time.now.utc)
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 2)
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should not send info email when user has entered credit card info" do
        user = Factory(:user, :cc_type => "Visa", :cc_last_digits => "1234")
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 2)
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should send warning email when user reach 90%" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 1.1)
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Warning! Trial Usage as reach 90%"
        
        user.reload.trial_usage_warning_email_sent_at.should be_present
      end
      
      it "should set trial_end_at, suspend account and sent email if user has no credit car when trial is over" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits)
        
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Your account has been suspended"
        last_delivery.body.to_s.should include "Trial is over!"
        
        user.reload.trial_ended_at.should be_present
        user.should be_suspended
      end
      
      it "should just set trial_end_at when trial is over and user has entered credit car inot" do
        user = Factory(:user, :cc_type => "Visa", :cc_last_digits => "1234")
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits)
        lambda { Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
        
        user.reload.trial_ended_at.should be_present
      end
      
      it "should launch delayed supervise_users" do
        lambda { Trial.supervise_users }.should change(Delayed::Job, :count).by(1)
      end
      
      it "should not launch delayed supervise_users if one pending already present" do
        Trial.supervise_users
        lambda { Trial.supervise_users }.should change(Delayed::Job, :count).by(0)
      end
      
    end
    
  end
  
  describe "user instance methods extension" do
    
    describe "trial_usage_percentage" do
      
      it "should be calculated only from current_invoice if user has no invoice" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 3)
        user.trial_usage_percentage.should == 33
      end
      
      pending "should be calculated from past invoice + current_invoice" do
        invoice = create_invoice(:loader_hits => Trial.free_loader_hits / 4, :calculate => true)
        Factory(:site, :user => invoice.user, :loader_hits_cache => Trial.free_loader_hits / 4)
        invoice.user.trial_usage_percentage.should == 50
      end
      
      it "should take the most used between loader_hits & player_hits" do
        Factory(:site, :user => user, :loader_hits_cache => Trial.free_loader_hits / 5, :player_hits_cache => Trial.free_player_hits / 4)
        user.trial_usage_percentage.should == 25
      end
      
      it "should be greather than 100 when over" do
        Factory(:site, :user => user, :player_hits_cache => Trial.free_player_hits * 2)
        user.trial_usage_percentage.should > 100
      end
      
    end
    
  end
  
end
