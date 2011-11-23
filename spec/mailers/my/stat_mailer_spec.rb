require 'spec_helper'

describe My::StatMailer do
  before(:all) do
    @user = Factory.create(:user)
    @site = Factory.create(:site, user: @user, stats_trial_started_at: 6.days.ago)
  end

  it_should_behave_like "common mailer checks", %w[stats_trial_will_end], params: Factory.create(:site, stats_trial_started_at: 6.days.ago)

  describe "#stats_trial_will_end" do
    before(:each) do
      described_class.stats_trial_will_end(@site).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql I18n.t('mailer.stat_mailer.stats_trial_will_end', hostname: @site.hostname)
      @last_delivery.body.encoded.should include "Dear #{@user.name},"
      @last_delivery.body.encoded.should include "2 days"
      @last_delivery.body.encoded.should include I18n.l(@site.stats_trial_ended_at, format: :named_date)
      @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.to_param}/plan/edit"
      @last_delivery.body.encoded.should include "https://docs.#{ActionMailer::Base.default_url_options[:host]}"
    end
  end

end
