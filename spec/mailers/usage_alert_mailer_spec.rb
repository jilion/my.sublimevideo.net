require 'spec_helper'

describe UsageAlertMailer do
  before(:all) do
    @site = Factory(:site)
    Factory(:plan, :price => @site.plan.price + 100)
  end
  subject { @site }

  it_should_behave_like "common mailer checks", %w[plan_player_hits_reached next_plan_recommended], :params => [Factory(:site)]

  describe "#plan_player_hits_reached" do
    before(:each) do
      UsageAlertMailer.plan_player_hits_reached(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should == "You have reached usage limit for your site #{subject.hostname}"
    end

    it "should set a body that contain the link to edit the credit card" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/edit#change_plan"
    end
  end

  describe "#next_plan_recommended" do
    before(:each) do
      UsageAlertMailer.next_plan_recommended(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should == "You should upgrade your site #{subject.hostname} to the next plan"
    end

    it "should set a body that contain the link to edit the credit card" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/edit#change_plan"
    end
  end
end
