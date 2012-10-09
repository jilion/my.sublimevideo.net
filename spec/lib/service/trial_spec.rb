require 'spec_helper'
require File.expand_path('lib/service/trial')

Site = Struct.new(:params) unless defined?(Site)

describe Service::Trial do
  let(:user) { create(:user) }
  let(:site0) { create(:site, user: user) }
  let(:site1) { create(:site, user: user) }
  let(:site2) { create(:site, user: user) }
  let(:site3) { create(:site, user: user) }
  let(:site4) { create(:site, user: user, state: 'archived') }
  let(:app_design_paid1) { create(:app_design, price: 995) }
  let(:app_design_paid2) { create(:app_design, price: 995) }
  let(:addon)            { create(:addon) }
  let(:addon_plan_paid0) { create(:addon_plan, addon: addon, price: 0) }
  let(:addon_plan_paid1) { create(:addon_plan, addon: addon, price: 995) }
  let(:addon_plan_paid2) { create(:addon_plan, addon: addon, price: 1995) }
  let(:delayed) { stub }
  let(:service) { stub }

  describe '.activate_billable_items_out_of_trial!' do
    before do
      Timecop.travel(15.days.ago) do
        create(:billable_item, site: site0, item: app_design_paid1, state: 'trial')
        create(:billable_item, site: site1, item: app_design_paid1, state: 'trial')
      end
      Timecop.travel(31.days.ago) do
        create(:billable_item, site: site1, item: addon_plan_paid2, state: 'trial')
        create(:billable_item, site: site2, item: addon_plan_paid1, state: 'trial')
        @billable_item3 = create(:billable_item, site: site3, item: addon_plan_paid1, state: 'trial')
        create(:billable_item, site: site4, item: addon_plan_paid1, state: 'trial')
      end
      @billable_item3.update_attribute(:state, 'subscribed')
    end

    it 'delays .activate_billable_items_out_of_trial_for_site! for site with at least a billable item out of trial' do
      described_class.should_receive(:delay).twice { delayed }
      delayed.should_receive(:activate_billable_items_out_of_trial_for_site!).with(site1.id)
      delayed.should_receive(:activate_billable_items_out_of_trial_for_site!).with(site2.id)

      described_class.activate_billable_items_out_of_trial!
    end
  end

  describe '.activate_billable_items_out_of_trial_for_site!' do
    before do
      Timecop.travel(15.days.ago) do
        create(:billable_item, site: site1, item: app_design_paid1, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid1, state: 'trial')
      end
      Timecop.travel(31.days.ago) do
        create(:billable_item, site: site1, item: app_design_paid2, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid2, state: 'trial')
      end
    end

    context 'user has a cc' do
      it 'delegates to Service::Site#update_billable_items! with the app designs and addon plans IDs' do
        Service::Site.should_receive(:new).with(site1) { service }
        service.should_receive(:update_billable_items!).with(
          { app_design_paid2.name => app_design_paid2.id },
          { addon_plan_paid2.addon.name => addon_plan_paid2.id }
        )

        described_class.activate_billable_items_out_of_trial_for_site!(site1.id)
      end
    end

    context 'user has no cc' do
      let(:user) { create(:user_no_cc) }

      it 'delegates to Service::Site#update_billable_items! and cancel the app designs and addon plans IDs' do
        Service::Site.should_receive(:new).with(site1) { service }
        service.should_receive(:update_billable_items!).with(
          { app_design_paid2.name => '0' },
          { addon_plan_paid2.addon.name => addon_plan_paid0.id }
        )

        described_class.activate_billable_items_out_of_trial_for_site!(site1.id)
      end
    end
  end

end
