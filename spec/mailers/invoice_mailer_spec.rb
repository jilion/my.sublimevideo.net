require 'spec_helper'

describe InvoiceMailer do
  before(:all) do
    Factory(:site).activate # just to have a delayed_job
    @invoice = Factory(:invoice, :ended_at => Time.utc(2010,1), :charging_delayed_job_id => Delayed::Job.last.id)
  end
  subject { @invoice }
  
  describe "invoice_completed common checks" do
    before(:each) do
      ActionMailer::Base.deliveries.clear
      InvoiceMailer.invoice_completed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    specify do
      ActionMailer::Base.deliveries.size.should == 1
      @last_delivery.from.should == ["noreply@sublimevideo.net"]
      @last_delivery.to.should == [subject.user.email]
      @last_delivery.content_type.should =~ /multipart\/mixed; boundary=\".+\"; charset=UTF-8/
    end
  end
  
  describe "charging_failed common checks" do
    before(:each) do
      ActionMailer::Base.deliveries.clear
      InvoiceMailer.charging_failed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    specify do
      ActionMailer::Base.deliveries.size.should == 1
      @last_delivery.from.should == ["noreply@sublimevideo.net"]
      @last_delivery.to.should == [subject.user.email]
      @last_delivery.content_type.should == "text/plain; charset=UTF-8"
    end
  end
  
  describe "#invoice_completed" do
    before(:each) do
      InvoiceMailer.invoice_completed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    specify do
      @last_delivery.subject.should == "January 2010 invoice is ready to be charged."
      @last_delivery.body.encoded.should include "if you have any question or doubt about its content, please use our support form:"
      @last_delivery.body.encoded.should include "/support"
    end
  end
  
  describe "#charging_failed" do
    before(:all) do
      InvoiceMailer.charging_failed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    specify do
      @last_delivery.subject.should == "January 2010 invoice charging has failed."
      @last_delivery.body.encoded.should include "Please update your credit card information here: http://my.sublimevideo.net/card/edit"
    end
  end
  
end