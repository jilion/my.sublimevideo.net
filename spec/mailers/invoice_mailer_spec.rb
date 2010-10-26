require 'spec_helper'

describe InvoiceMailer do
  subject { Factory(:invoice, :user => @user).reload } # reload needed to have Time as Date
  
  before(:each) do
    @user = Factory(:user, :last_invoiced_on => (1.month + 1.day).ago, :next_invoiced_on => 1.day.ago)
    Factory(:site, :user => @user, :loader_hits_cache => 100000)
    subject
    ActionMailer::Base.deliveries.clear
  end
  
  describe "common checks" do
    %w[invoice_calculated].each do |mail|
      before(:each) do
        InvoiceMailer.send(mail, subject).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end
      
      it "should send an email" do
        ActionMailer::Base.deliveries.size.should == 1
      end
      
      it "should send the mail from noreply@sublimevideo.net" do
        @last_delivery.from.should == ["noreply@sublimevideo.net"]
      end
      
      it "should send the mail to user.email" do
        @last_delivery.to.should == [subject.user.email]
      end
      
      it "should set content_type to text/plain (set by default by the Mail gem)" do
        @last_delivery.content_type.should == "text/plain; charset=UTF-8"
      end
    end
  end
  
  describe "#invoice_calculated" do
    before(:each) do
      InvoiceMailer.invoice_calculated(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set subject to Liquidified template.subject" do
      @last_delivery.subject.should == "Invoice ready to be charged"
    end
    
    it "should set a body that contain the invoice amount" do
      @last_delivery.body.raw_source.should include "$#{subject.amount / 100.0}"
    end
  end
  
end