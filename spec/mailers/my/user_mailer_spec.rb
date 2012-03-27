require 'spec_helper'

describe My::UserMailer do
  subject { create(:user) }

  it_should_behave_like "common mailer checks", %w[account_suspended account_unsuspended account_archived], params: FactoryGirl.create(:user)

  describe "#account_suspended" do
    context "when reason given is :invoice_problem" do
      before do
        described_class.account_suspended(subject).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it "should set proper subject" do
        @last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_suspended')
      end

      it "should set a body that contain info" do
        @last_delivery.body.encoded.should include "Your account has been suspended."
      end
    end
  end

  describe "#account_unsuspended" do
    before do
      described_class.account_unsuspended(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      @last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_unsuspended')
    end

    it "should set a body that contain info" do
      @last_delivery.body.encoded.should include "Your account has been reactivated."
    end
  end

  describe "#account_archived" do
    before do
      described_class.account_archived(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      @last_delivery.subject.should eql I18n.t('mailer.user_mailer.account_archived')
    end

    it "should set a body that contain info" do
      @last_delivery.body.encoded.should include "Your account has been deleted."
    end
  end

end
