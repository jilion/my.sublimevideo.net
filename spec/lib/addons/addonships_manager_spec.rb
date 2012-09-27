require 'fast_spec_helper'
require File.expand_path('lib/addons/addonships_manager')

Site = Class.new unless defined?(Site)
Addons::Addon = Class.new unless defined?(Addons::Addon)

describe Addons::AddonshipsManager do
  let(:site)    { stub(:site, id: 4321) }
  let(:addon)   { stub(:addon, category: 'logo', id: 1234) }
  let(:manager) { stub }

  describe '.update_addonships_for_site!' do
    before do
      Addons::Addon.should_receive(:transaction).and_yield
    end

    it 'activate addons with new status == 1' do
      Addons::Addon.should_receive(:find_by_category_and_name) { addon }
      Addons::AddonshipManager.should_receive(:new).with(site, addon) { manager }
      manager.should_receive(:activate!) { true }

      described_class.update_addonships_for_site!(site, logo: 'no-logo')
    end

    it 'deactivate addons with new status == 0' do
      Addons::AddonshipManager.should_receive(:new).with(site) { manager }
      manager.should_receive(:deactivate_addonships_in_category!).with(:stats)

      described_class.update_addonships_for_site!(site, stats: '0')
    end
  end

  describe '.activate_addonships_out_of_trial!' do
    it 'calls .activate_addonships_out_of_trial_for_site! for each site with addonships out of trial' do
      Site.stub_chain(:with_out_of_trial_addons, :find_each).and_yield(site)

      delayed_job = stub
      described_class.should_receive(:delay) { delayed_job }
      delayed_job.should_receive(:activate_addonships_out_of_trial_for_site!).with(site.id)

      described_class.activate_addonships_out_of_trial!
    end
  end

  describe '.activate_addonships_out_of_trial_for_site!' do
    before do
      Addons::Addon.should_receive(:transaction).and_yield
    end

    it 'activate the addon' do
      Site.should_receive(:find).with(site.id) { site }
      site.stub_chain(:addons, :out_of_trial) { [addon] }
      Addons::AddonshipManager.should_receive(:new).with(site, addon) { manager }
      manager.should_receive(:activate!) { true }

      described_class.activate_addonships_out_of_trial_for_site!(site.id)
    end
  end

end
