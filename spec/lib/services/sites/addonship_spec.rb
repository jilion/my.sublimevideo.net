require 'fast_spec_helper'
require File.expand_path('lib/services/sites/addonship')

describe Services::Sites::Addonship do
  unless defined?(Site)
    before do
      Site = Class.new
    end
    after { Object.send(:remove_const, :Site) }
  end
  unless defined?(Addons)
    before do
      Addons = Module.new
    end
    after { Object.send(:remove_const, :Addons) }
  end
  unless defined?(Addons::Addon)
    before do
      Addons::Addon = Class.new
    end
    after { Addons.send(:remove_const, :Addon) }
  end

  let(:site)              { stub(:site, id: 4321) }
  let(:no_logo_addon)     { stub(:addon, category: 'logo', name: 'no-logo', id: 1234) }
  let(:custom_logo_addon) { stub(:addon, category: 'logo', name: 'custom-logo', id: 2345) }
  let(:addonship)         { stub(addon: no_logo_addon) }
  let(:addonship2)        { stub(addon: custom_logo_addon) }
  let(:manager)           { described_class.new(site) }
  let(:null_manager)      { stub.as_null_object }

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
      site.stub_chain(:addons, :out_of_trial) { [no_logo_addon] }
      described_class.should_receive(:new).with(site) { null_manager }
      null_manager.should_receive(:activate_addonship!).with(no_logo_addon) { true }

      described_class.activate_addonships_out_of_trial_for_site!(site.id)
    end
  end

  describe '#update_addonships!' do
    before do
      Addons::Addon.should_receive(:transaction).and_yield
    end

    context 'hash value is 0' do
      it 'deactivates all addons in category' do
        manager.should_not_receive(:activate_addonship!)
        manager.should_receive(:deactivate_addonships_in_category!).with(:stats, nil)

        manager.update_addonships!(stats: '0')
      end
    end

    context 'hash value is a string' do
      it 'activates the given add-on and deactivate all other addons in category' do
        Addons::Addon.should_receive(:get).with('logo', 'no-logo') { no_logo_addon }
        manager.should_receive(:activate_addonship!).with(no_logo_addon) { true }
        manager.should_receive(:deactivate_addonships_in_category!).with(:logo, no_logo_addon)

        manager.update_addonships!(logo: 'no-logo')
      end
    end
  end

  describe '#activate_addonship!' do

    context 'addonship is active' do
      before do
        site.should_receive(:addon_is_active?).with(no_logo_addon) { true }
      end

      it 'does nothing' do
        manager.should_not_receive(:addonship_from_addon)

        manager.activate_addonship!(no_logo_addon)
      end
    end

    context 'addonship is not active' do
      before do
        site.should_receive(:addon_is_active?).with(addon) { false }
        manager.should_receive(:addonship_from_addon).with(addon) { addonship }
      end

      context 'addonship is not out of trial' do
        before do
          manager.stub(:addonship_out_of_trial?) { false }
        end

        context 'addon is in beta' do
          let(:addon) { stub(:addon, beta?: true) }

          it 'deactivate all addons in the category and activate the given addon' do
            addonship.should_receive(:start_beta!)

            manager.activate_addonship!(addon)
          end
        end

        context 'addon is public and free' do
          let(:addon) { stub(:addon, beta?: false, price: 0) }

          it 'deactivate all addons in the category and activate the given addon' do
            addonship.should_receive(:subscribe!)

            manager.activate_addonship!(addon)
          end
        end

        context 'addon is public and paying' do
          let(:addon) { stub(:addon, beta?: false, price: 999) }

          it 'deactivate all addons in the category and activate the given addon' do
            addonship.should_receive(:start_trial!)

            manager.activate_addonship!(addon)
          end
        end
      end

      context 'addonship is out of trial' do
        before do
          manager.stub(:addonship_out_of_trial?) { true }
        end

        context 'addon is in beta' do
          let(:addon) { stub(:addon, beta?: true) }

          it 'deactivate all addons in the category and activate the given addon' do
            addonship.should_receive(:start_beta!)

            manager.activate_addonship!(addon)
          end
        end

        context 'addon is public' do
          let(:addon) { stub(:addon, beta?: false) }

          it 'deactivate all addons in the category and activate the given addon' do
            addonship.should_receive(:subscribe!)

            manager.activate_addonship!(addon)
          end
        end
      end
    end
  end

  describe '#deactivate_addonships_in_category!' do
    let(:manager) { described_class.new(site) }
    before { manager.should_receive(:addonships_in_category) { [addonship, addonship2] } }

    it 'deactivate all active addons in the category' do
      site.should_receive(:addon_is_active?).with(addonship.addon) { false }
      site.should_receive(:addon_is_active?).with(addonship2.addon) { true }
      addonship.should_not_receive(:cancel!)
      addonship2.should_receive(:cancel!)

      manager.deactivate_addonships_in_category!('logo')
    end
  end

  describe '#addonship_out_of_trial?' do
    context 'trial started just now' do
      it { manager.send(:addonship_out_of_trial?, stub(trial_started_on: Time.now), Time.now - (30 * 24 * 3600)).should be_false }
    end

    context 'trial started 30 days and 1 second ago' do
      it { manager.send(:addonship_out_of_trial?, stub(trial_started_on: Time.now - (30 * 24 * 3600) - 1), Time.now - (30 * 24 * 3600)).should be_true }
    end
  end

  describe '#free_addon?' do
    context 'addon has a price == 0' do
      it { described_class.new(site).send(:free_addon?, stub(price: 0)).should be_true }
    end

    context 'addon has a price != 0' do
      it { described_class.new(site).send(:free_addon?, stub(price: 1)).should be_false }
    end
  end

end
