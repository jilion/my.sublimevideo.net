require 'spec_helper'

describe My::SitesHelper do

  describe "#full_days_until_trial_end" do
    it { helper.full_days_until_trial_end(Factory.build(:new_site, trial_started_at: Time.now.utc.midnight)).should eq BusinessModel.days_for_trial-1 }
    it { helper.full_days_until_trial_end(Factory.build(:new_site, trial_started_at: 1.day.ago.midnight)).should eq BusinessModel.days_for_trial-2 }
    it { helper.full_days_until_trial_end(Factory.build(:new_site, trial_started_at: BusinessModel.days_for_trial.days.ago.midnight + 25.hours)).should eq 1 }
    it { helper.full_days_until_trial_end(Factory.build(:new_site, trial_started_at: BusinessModel.days_for_trial.days.ago.midnight + 1.minute)).should eq 0 }
    it { helper.full_days_until_trial_end(Factory.build(:new_site, trial_started_at: BusinessModel.days_for_trial.days.ago.midnight - 1.minute)).should eq 0 }
  end

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = Factory.create(:site)
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
      subject { Factory.create(:site, hostname: 'rymai.me') }

      specify { helper.hostname_or_token(subject).should eq 'rymai.me' }
    end

    context "site without a hostname" do
      subject { Factory.create(:site, plan_id: @free_plan.id, hostname: '') }

      specify { helper.hostname_or_token(subject).should eq subject.token }
    end
  end

end
