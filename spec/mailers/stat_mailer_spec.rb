require 'spec_helper'

describe StatMailer do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @site = FactoryGirl.create(:site, user: @user, stats_trial_started_at: 6.days.ago)
  end

  it_should_behave_like "common mailer checks", %w[stats_trial_will_end], params: FactoryGirl.create(:site, stats_trial_started_at: 6.days.ago)

  describe "#stats_trial_will_end" do
    before(:each) do
      described_class.stats_trial_will_end(@site).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql "Your stats trial for #{@site.hostname.presence || 'your site'} will expire in #{BusinessModel.days_for_stats_trial-6} days"
      @last_delivery.body.encoded.should include "Dear #{@user.full_name},"
      @last_delivery.body.encoded.should include "#{BusinessModel.days_for_stats_trial-6} days"
      @last_delivery.body.encoded.should include I18n.l(@site.stats_trial_ended_at, format: :named_date)
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.token}/plan/edit"
      @last_delivery.body.encoded.should include "http://docs.sublimevideo.net"
    end
  end

end
