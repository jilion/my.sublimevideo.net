require 'spec_helper'

describe My::UsageMonitoringMailer do

  before(:all) do
    @site = Factory.create(:site)
    Factory.create(:plan, price: @site.plan.price + 100)
  end
  subject { @site }

  it_should_behave_like "common mailer checks", %w[plan_overused], params: Factory.create(:site)

  describe "#plan_overused" do
    before(:each) do
      described_class.plan_overused(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should eq I18n.t('mailer.usage_monitoring_mailer.plan_overused', hostname: subject.hostname)
    end

    it "should set a body that contain the link to peak insurance docs" do
      @last_delivery.body.encoded.should include "http://docs.#{ActionMailer::Base.default_url_options[:host]}/peak-insurance"
    end
  end

  it_should_behave_like "common mailer checks", %w[plan_upgrade_required], params: Factory.create(:site)

  describe "#plan_upgrade_required" do
    before(:each) do
      described_class.plan_upgrade_required(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject" do
      @last_delivery.subject.should eq I18n.t('mailer.usage_monitoring_mailer.plan_upgrade_required', hostname: subject.hostname)
    end

    it "should set a body that contain the link to edit the plan" do
      @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{subject.to_param}/plan/edit"
    end
  end

end
