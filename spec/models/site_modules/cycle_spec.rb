require 'spec_helper'

describe SiteModules::Cycle do
  describe 'Class Methods' do

    pending '.downgrade_sites_leaving_trial' do
      let(:site) { create(:site, plan_id: @trial_plan.id) }

      context 'site with trial ended' do
        it 'downgrades to the Free plan' do
          site.should be_in_trial_plan

          Timecop.travel((BusinessModel.days_for_trial).days.from_now) { Site.downgrade_sites_leaving_trial }

          site.reload.should be_in_free_plan
        end
      end

      context 'site with trial not ended' do
        it 'dont downgrade to the Free plan' do
          site.should be_in_trial_plan

          Timecop.travel((BusinessModel.days_for_trial - 1).days.from_now) { Site.downgrade_sites_leaving_trial }

          site.reload.should be_in_trial_plan
        end
      end
    end # .downgrade_sites_leaving_trial

  end # Class Methods

  describe "Instance Methods" do

    pending "#trial_end" do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial     = create(:site, plan_id: @trial_plan.id)
      end

      specify { @site_not_in_trial.trial_end.should be_nil }
      specify { @site_in_trial.trial_end.should eq BusinessModel.days_for_trial.days.from_now.yesterday.end_of_day }
    end # #trial_end

    pending "#trial_expires_on & #trial_expires_in_less_than_or_equal_to" do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial     = create(:site, plan_id: @trial_plan.id)
      end

      specify { @site_not_in_trial.trial_expires_on(BusinessModel.days_for_trial.days.from_now).should be_false }
      specify { @site_in_trial.trial_expires_on(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now - 1.day).should be_false }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now + 1.day).should be_true }
    end # #trial_expires_on & #trial_expires_in_less_than_or_equal_to

  end # Instance Methods

end
