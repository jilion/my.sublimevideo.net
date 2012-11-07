require 'spec_helper'

describe LayoutHelper, :plans do

  describe '#sticky_notices' do
    let(:user)                   { stub }
    let(:sites)                  { stub }
    let(:site_will_leave_trial)  { stub }
    let(:sites_will_leave_trial) { [{ site: site_will_leave_trial }] }
    before do
      helper.should_receive(:credit_card_warning).with(user).and_return(true)
      helper.should_receive(:billing_address_incomplete).with(user).and_return(true)
      helper.should_receive(:sites_with_trial_expires_in_less_than_5_days).with(sites).and_return(sites_will_leave_trial)
    end

    it {
      helper.sticky_notices(user, sites).should == {
        credit_card_warning: true,
        billing_address_incomplete: true,
        sites_with_trial_expires_in_less_than_5_days: [{ site: site_will_leave_trial }]
      }
    }
  end

  describe "#full_days_until_trial_end" do
    before { BusinessModel.stub(:days_for_trial) { 3 } }

    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: Time.now.utc)).should eq 3 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 1.day.ago)).should eq 2 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 2.days.ago)).should eq 1 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 3.days.ago)).should eq 0 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 4.days.ago)).should eq 0 }
  end

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = build(:fake_site)
      helper.sublimevideo_script_tag_for(site).should eq "<script type=\"text/javascript\" src=\"//cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
    end
  end

  describe "#style_for_usage_bar_from_usage_percentage" do
    it { helper.style_for_usage_bar_from_usage_percentage(0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.02).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.04).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.05).should eq "width:5%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.12344).should eq "width:12.34%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.783459).should eq "width:78.35%;" }
  end

  describe "#hostname_or_token" do
    context "site with a hostname" do
      let(:site) { build(:fake_site, hostname: 'rymai.me') }

      specify { helper.hostname_or_token(site).should eq 'rymai.me' }
    end

    context "site without a hostname" do
      let(:site) { build(:fake_site, plan_id: @free_plan.id, hostname: '') }

      specify { helper.hostname_or_token(site).should eq "##{site.token}" }
    end
  end

end
