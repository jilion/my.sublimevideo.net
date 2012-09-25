require 'fast_spec_helper'
require 'support/stubs'
require File.expand_path('lib/addons/addonship_manager')

Addons::Addon = Class.new unless defined?(Addons::Addon)

describe Addons::AddonshipManager do
  let(:site)      { stub(:site) }
  let(:addon)     { stub(:addon, category: 'logo', id: 1234) }
  let(:addonship) { Struct.new(:state).new }
  let(:manager)   { described_class.new(site, addon) }

  describe '.update_addonships_for_site!' do
    let(:manager) { stub(:manager) }
    before do
      Addons::Addon.should_receive(:transaction).and_yield
    end

    it 'activate addons with new status == 1' do
      Addons::Addon.should_receive(:find_by_category_and_name) { addon }
      described_class.should_receive(:new).with(site, addon) { manager }
      manager.should_receive(:activate!)

      described_class.update_addonships_for_site!(site, logo: 'no-logo')
    end

    it 'deactivate addons with new status == 0' do
      described_class.should_receive(:new).with(site) { manager }
      manager.should_receive(:deactivate_addonships_in_category!).with(:stats)

      described_class.update_addonships_for_site!(site, stats: '0')
    end
  end

  describe '#activate!' do
    before do
      manager.stub(:addonship) { addonship }
    end

    context 'addon is already activated' do
      it 'does nothing' do
        site.should_receive(:addon_is_active?).with(addon) { true }

        manager.activate!
      end
    end

    context 'addon is not already activated' do
      before do
        site.should_receive(:addon_is_active?).with(addon) { false }
      end

      it 'deactivate all addonships in the category and activate the given addon' do
        manager.should_receive(:deactivate_addonships_in_category!).with('logo', except_addon_id: 1234)
        manager.should_receive(:activate_addonship)

        manager.activate!
      end
    end
  end

  describe '#deactivate_addonships_in_category!' do
    let(:manager) { described_class.new(site) }

    it 'deactivate all addons in the category and activate the given addon' do
      manager.should_receive(:addonships_in_category) { [addonship] }
      addonship.should_receive(:cancel!)

      manager.deactivate_addonships_in_category!('logo')
    end
  end

  describe '#activate_addonship' do
    before do
      manager.stub(:addonship) { addonship }
    end

    context 'addonship is not out of trial'do
      before do
        manager.stub(:out_of_trial?) { false }
      end

      context 'addon is in beta' do
        let(:addon) { stub(:addon, beta?: true) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:save!)

          manager.send(:activate_addonship)

          addonship.state.should == 'beta'
        end
      end

      context 'addon is public and free' do
        let(:addon) { stub(:addon, beta?: false, price: 0) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:save!)

          manager.send(:activate_addonship)
          addonship.state.should == 'paying'
        end
      end

      context 'addon is public and paying' do
        let(:addon) { stub(:addon, beta?: false, price: 999) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:save!)

          manager.send(:activate_addonship)
          addonship.state.should == 'trial'
        end
      end
    end

    context 'addonship is out of trial' do
      before do
        manager.stub(:out_of_trial?) { true }
      end

      context 'addon is in beta' do
        let(:addon) { stub(:addon, beta?: true) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:save!)

          manager.send(:activate_addonship)
          addonship.state.should == 'beta'
        end
      end

      context 'addon is public' do
        let(:addon) { stub(:addon, beta?: false) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:save!)

          manager.send(:activate_addonship)
          addonship.state.should == 'paying'
        end
      end

    end
  end

  describe '#out_of_trial?' do
    context 'trial started just now' do
      before do
        manager.stub(:addonship) { stub(trial_started_on: Time.now) }
      end

      it { manager.out_of_trial?(Time.now - (30 * 24 * 3600)).should be_false }
    end

    context 'trial started 30 days and 1 second ago' do
      before do
        manager.stub(:addonship) { stub(trial_started_on: Time.now - (30 * 24 * 3600) - 1) }
      end

      it { manager.out_of_trial?(Time.now - (30 * 24 * 3600)).should be_true }
    end
  end

  describe '#free_addon?' do
    context 'addon has a price == 0' do
      it { described_class.new(site, stub(price: 0)).should be_free_addon }
    end

    context 'addon has a price != 0' do
      it { described_class.new(site, stub(price: 1)).should_not be_free_addon }
    end
  end

end
