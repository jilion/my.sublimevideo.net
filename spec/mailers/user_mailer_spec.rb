require 'spec_helper'

describe UserMailer do
  subject { create(:user) }

  it_should_behave_like "common mailer checks", %w[welcome], params: FactoryGirl.create(:user), no_signature: true
  it_should_behave_like "common mailer checks", %w[account_suspended account_unsuspended account_archived], params: FactoryGirl.create(:user)

  describe "#welcome" do
    before do
      described_class.welcome(subject).deliver
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      last_delivery.subject.should eql I18n.t('mailer.user_mailer.welcome')
    end

    it "should set a body that contain info" do
      last_delivery.body.encoded.should include "Welcome to SublimeVideo!"
    end
  end

  describe "#account_suspended" do
    before do
      described_class.account_suspended(subject).deliver
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_suspended')
    end

    it "should set a body that contain info" do
      last_delivery.body.encoded.should include "Your SublimeVideo account has been suspended due to non-payment."
    end
  end

  describe "#account_unsuspended" do
    before do
      described_class.account_unsuspended(subject).deliver
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_unsuspended')
    end

    it "should set a body that contain info" do
      last_delivery.body.encoded.should include "Your SublimeVideo account has been reactivated."
    end
  end

  describe "#account_archived" do
    before do
      described_class.account_archived(subject).deliver
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_archived')
    end

    it "should set a body that contain info" do
      last_delivery.body.encoded.should include "This is to confirm that the cancellation of your SublimeVideo account"
    end
  end

end