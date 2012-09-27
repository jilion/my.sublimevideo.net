require 'fast_spec_helper'
require File.expand_path('lib/addons/addonship_manager')

Addons::Addon = Class.new unless defined?(Addons::Addon)

describe Addons::AddonshipManager do
  let(:site)      { stub(:site) }
  let(:addon)     { stub(:addon, category: 'logo', id: 1234) }
  let(:addonship) { Struct.new(:state).new }
  let(:manager)   { described_class.new(site, addon) }

  describe '#activate!' do
    before do
      manager.stub(:addonship) { addonship }
    end

    context 'addon is already activated' do
      it 'does nothing' do
        manager.should_receive(:active?) { true }

        manager.activate!
      end
    end

    context 'addon is not already activated' do
      before do
        manager.should_receive(:active?) { false }
      end

      it 'deactivate all addonships in the category and activate the given addon' do
        manager.should_receive(:deactivate_addonships_in_category!).with('logo', except_addon_id: 1234)
        manager.should_receive(:activate_addonship!)

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

  describe '#activate_addonship!' do
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
          addonship.should_receive(:start_beta!)

          manager.send(:activate_addonship!)
        end
      end

      context 'addon is public and free' do
        let(:addon) { stub(:addon, beta?: false, price: 0) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:subscribe!)

          manager.send(:activate_addonship!)
        end
      end

      context 'addon is public and paying' do
        let(:addon) { stub(:addon, beta?: false, price: 999) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:start_trial!)

          manager.send(:activate_addonship!)
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
          addonship.should_receive(:start_beta!)

          manager.send(:activate_addonship!)
        end
      end

      context 'addon is public' do
        let(:addon) { stub(:addon, beta?: false) }

        it 'deactivate all addons in the category and activate the given addon' do
          addonship.should_receive(:subscribe!)

          manager.send(:activate_addonship!)
        end
      end

    end
  end

  describe '#active?' do
    context 'addon is not active' do
      before do
        site.should_receive(:addon_is_active?).with(addon) { false }
      end

      it 'asks the site if the addon is active' do
        manager.should_not be_active
      end
    end

    context 'addon is active' do
      before do
        site.should_receive(:addon_is_active?).with(addon) { true }
      end

      it 'asks the site if the addon is active' do
        manager.should be_active
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

  describe '#free?' do
    context 'addon has a price == 0' do
      it { described_class.new(site, stub(price: 0)).should be_free }
    end

    context 'addon has a price != 0' do
      it { described_class.new(site, stub(price: 1)).should_not be_free }
    end
  end

end
