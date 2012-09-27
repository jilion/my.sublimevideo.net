# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    before do
      create(:site)
      create(:site, state: 'archived')
      Delayed::Job.delete_all
    end

    it 'regenerates loader and license of all sites' do
      expect { described_class.regenerate_templates(loaders: true) }.to change(
        Delayed::Job.where{ handler =~ '%Player::Loader%update_all_modes%' }, :count
      ).by(1)
      expect { described_class.regenerate_templates(settings: true) }.to change(
        Delayed::Job.where{ handler =~ '%Player::Settings%update_all_types%' }, :count
      ).by(1)
    end
  end

  describe '.update_sites_in_trial_to_new_trial_plan', :plans do
    before do
      @site1 = create(:fake_site, plan_id: @paid_plan.id, trial_started_at: Time.now.midnight)
      @site2 = create(:fake_site, plan_id: @paid_plan.id, trial_started_at: 13.days.ago)
      @site3 = create(:fake_site, plan_id: @paid_plan.id, trial_started_at: Time.now.midnight, state: 'archived')
    end

    it 'updates plan to trial plan for non-archived sites' do
      described_class.update_sites_in_trial_to_new_trial_plan

      @site1.reload.plan.should eq @trial_plan
      @site1.plan_started_at.should eq Time.now.midnight
      @site2.reload.plan.should eq @trial_plan
      @site2.plan_started_at.should eq 13.days.ago.midnight
      @site3.reload.plan.should eq @paid_plan
    end
  end

end
