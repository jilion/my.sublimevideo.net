require 'spec_helper'

describe SitesHelper, :plans do

  describe "#full_days_until_trial_end" do
    before { BusinessModel.stub(:days_for_trial) { 3 } }

    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: Time.now.utc)).should eq 3 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 1.day.ago)).should eq 2 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 2.days.ago)).should eq 1 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 3.days.ago)).should eq 0 }
    it { helper.full_days_until_trial_end(build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 4.days.ago)).should eq 0 }
  end

  describe '#display_plan' do
    let(:trial_site)           { build(:fake_site, plan_id: @trial_plan.id) }
    let(:free_site)            { build(:fake_site, plan_id: @free_plan.id) }
    let(:paid_site)            { build(:fake_site, plan_id: @paid_plan.id) }
    let(:paid_site_with_next)  { build(:fake_site, plan_id: @paid_plan.id, next_cycle_plan_id: @free_plan.id) }

    it { helper.display_plan(trial_site).should eq 'Trial' }
    it { helper.display_plan(free_site).should eq 'Free plan' }
    it { helper.display_plan(paid_site).should eq "#{@paid_plan.title} plan"}
    it { helper.display_plan(paid_site_with_next).should eq "#{@paid_plan.title} plan<span class=\"disabled\"> =&gt; Free plan</span>" }
  end

  describe '#sites_with_trial_expires_in_less_than_5_days' do
    before { BusinessModel.stub(:days_for_trial) { 10 } }

    let(:site1) { build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 6.days.ago) }
    let(:site2) { build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 5.days.ago) }
    let(:site3) { build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 4.days.ago) }
    let(:site4) { build(:fake_site, plan_id: @trial_plan.id, plan_started_at: 11.days.ago) }
    let(:sites) { [site1, site2, site3, site4] }

    it { helper.sites_with_trial_expires_in_less_than_5_days(sites).should eq [{ site: site1 }] }
  end

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = build(:fake_site)
      helper.sublimevideo_script_tag_for(site).should eq "<script type=\"text/javascript\" src=\"http://cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
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
