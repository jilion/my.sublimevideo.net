require 'spec_helper'

describe UsageAlertMailer do
  before(:all) do
    @site = Factory(:site)
  end
  subject { @site }
  
  it_should_behave_like "common mailer checks", %w[limit_reached], :params => [Factory(:site)]
  
  describe "#limit_reached" do
    before(:each) do
      UsageAlertMailer.limit_reached(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set subject" do
      @last_delivery.subject.should == "You have reached usage limit for your site #{subject.hostname}"
    end
    
    it "should set a body that contain the link to edit the credit card" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/edit"
    end
  end
  
end