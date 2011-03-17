require 'spec_helper'

describe UsageMonitoringMailer do
  before(:all) do
    @site = Factory(:site)
    Factory(:plan, :price => @site.plan.price + 100)
  end
  subject { @site }

  it_should_behave_like "common mailer checks", %w[plan_player_hits_reached], :params => [Factory(:site)]

  describe "#plan_player_hits_reached" do
    before(:each) do
      UsageMonitoringMailer.plan_player_hits_reached(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should == "You have reached usage limit for your site #{subject.hostname}"
    end

    it "should set a body that contain the link to edit the plan" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/plan/edit"
    end
  end

  it_should_behave_like "common mailer checks", %w[plan_upgrade_required], :params => [Factory(:site)]

  describe "#plan_upgrade_required" do
    before(:each) do
      UsageMonitoringMailer.plan_upgrade_required(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should == "You need to upgrade your plan for your site #{@site.hostname}"
    end

    it "should set a body that contain the link to edit the plan" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/plan/edit"
    end
  end

end
