require 'fast_spec_helper'
require 'support/stubs'
require File.expand_path('lib/addons/addonship_manager')

describe Addons::AddonshipManager do
  let(:addon_class) { stub(:addon_class) }
  let(:addonships) { stub(:addonships) }
  let(:site) { stub(:site) }
  let(:manager) { described_class.new(site, addon_class) }
  before do
    @logo_addon1 = stub(category: 'logo', name: 'sublime', id: 4321)
    @logo_addon2 = stub(category: 'logo', name: 'no-logo', id: 1234)
    @logo_addon3 = stub(category: 'logo', name: 'custom-logo')
    @stats_addon = stub(category: 'stats', name: 'standard')
    @support_addon1 = stub(category: 'support', name: 'standard')
    @support_addon2 = stub(category: 'support', name: 'vip')
    @addonship1 = stub(site: site, addon: @logo_addon1, state: 'paying')
    @addonship2 = stub(site: site, addon: @logo_addon2, state: 'canceled')
    @addonship3 = stub(site: site, addon: @stats_addon, state: 'canceled')
  end

  describe '.update_addonships!' do
    it 'activate addons with new status == 1' do
      addon_class.should_receive(:transaction).and_yield
      addon_class.should_receive(:find_by_category_and_name).with('logo', 'no-logo') { @logo_addon2 }
      manager.should_receive(:activate_addon!).with(@logo_addon2)

      manager.update_addonships!(logo: 'no-logo')
    end

    it 'deactivate addons with new status == 0' do
      addon_class.should_receive(:transaction).and_yield
      manager.should_receive(:deactivate_addons_in_category!).with(:stats)

      manager.update_addonships!(stats: '0')
    end
  end

  describe '.activate_addon!' do
    context 'addon is already activated' do
      it 'does nothing' do
        site.should_receive(:addon_is_active?).with(@logo_addon2) { true }

        manager.activate_addon!(@logo_addon2)
      end
    end

    context 'addon is not already activated' do
      it 'deactivate all addonships in the category and activate the given addon' do
        site.should_receive(:addon_is_active?).with(@logo_addon2) { false }
        manager.should_receive(:deactivate_addonships_in_category).with('logo', except_addon_id: 1234)
        manager.should_receive(:activate_addonship).with(@logo_addon2)

        manager.activate_addon!(@logo_addon2)
      end
    end
  end

  describe '.deactivate_addons_in_category!' do
    it 'deactivate all addons in the category' do
      manager.should_receive(:deactivate_addonships_in_category).with('logo')

      manager.deactivate_addons_in_category!('logo')
    end
  end

  describe '.deactivate_addonships_in_category' do
    it 'deactivate all addons in the category and activate the given addon' do
      site.should_receive(:addonships) { addonships }
      addonships_in_category = [@addonship1, @addonship2]
      addonships.should_receive(:in_category).with('logo') { addonships_in_category }
      addonships_in_category.should_receive(:except_addon_id).with(4321) { [@addonship2] }
      @addonship2.should_receive(:cancel!)

      manager.send(:deactivate_addonships_in_category, 'logo', except_addon_id: @logo_addon1.id)
    end
  end

  describe '.activate_addonship' do
    before do
      site.should_receive(:addonships) { addonships }
    end

    context 'addonship is new' do
      let(:new_addonship) { stub(:new_addonship) }
      before do
        addonships.should_receive(:find_or_initialize_by_addon_id).with(1234) { new_addonship }
        new_addonship.stub(:out_of_trial?) { false }
      end

      context 'addon is in beta' do
        before do
          @logo_addon2.should_receive(:beta?) { true }
        end

        it 'deactivate all addons in the category and activate the given addon' do
          new_addonship.should_receive(:state=).with('beta')
          new_addonship.should_receive(:save!)

          manager.send(:activate_addonship, @logo_addon2)
        end
      end

      context 'addon is public and free' do
        before do
          @logo_addon2.should_receive(:beta?) { false }
          @logo_addon2.should_receive(:price) { 0 }
        end

        it 'deactivate all addons in the category and activate the given addon' do
          new_addonship.should_receive(:state=).with('paying')
          new_addonship.should_receive(:save!)

          manager.send(:activate_addonship, @logo_addon2)
        end
      end

      context 'addon is public and paying' do
        before do
          @logo_addon2.should_receive(:beta?) { false }
          @logo_addon2.should_receive(:price) { 999 }
        end

        it 'deactivate all addons in the category and activate the given addon' do
          new_addonship.should_receive(:state=).with('trial')
          new_addonship.should_receive(:save!)

          manager.send(:activate_addonship, @logo_addon2)
        end
      end
    end

    context 'addonship is persisted' do
      before do
        addonships.should_receive(:find_or_initialize_by_addon_id).with(1234) { @addonship2 }
      end

      context 'addonship is not out of trial' do
        before do
          @addonship2.stub(:out_of_trial?) { false }
        end

        context 'addon is in beta' do
          before do
            @logo_addon2.should_receive(:beta?) { true }
          end

          it 'deactivate all addons in the category and activate the given addon' do
            @addonship2.should_receive(:state=).with('beta')
            @addonship2.should_receive(:save!)

            manager.send(:activate_addonship, @logo_addon2)
          end
        end

        context 'addon is public and free' do
          before do
            @logo_addon2.should_receive(:beta?) { false }
            @logo_addon2.should_receive(:price) { 0 }
          end

          it 'deactivate all addons in the category and activate the given addon' do
            @addonship2.should_receive(:state=).with('paying')
            @addonship2.should_receive(:save!)

            manager.send(:activate_addonship, @logo_addon2)
          end
        end

        context 'addon is public and paying' do
          before do
            @logo_addon2.should_receive(:beta?) { false }
            @logo_addon2.should_receive(:price) { 999 }
          end

          it 'deactivate all addons in the category and activate the given addon' do
            @addonship2.should_receive(:state=).with('trial')
            @addonship2.should_receive(:save!)

            manager.send(:activate_addonship, @logo_addon2)
          end
        end
      end

      context 'addonship is out of trial' do
        before do
          @addonship2.stub(:out_of_trial?) { true }
        end

        context 'addon is in beta' do
          before do
            @logo_addon2.should_receive(:beta?) { true }
          end

          it 'deactivate all addons in the category and activate the given addon' do
            @addonship2.should_receive(:state=).with('beta')
            @addonship2.should_receive(:save!)

            manager.send(:activate_addonship, @logo_addon2)
          end
        end

        context 'addon is public' do
          before do
            @logo_addon2.should_receive(:beta?) { false }
          end

          it 'deactivate all addons in the category and activate the given addon' do
            @addonship2.should_receive(:state=).with('paying')
            @addonship2.should_receive(:save!)

            manager.send(:activate_addonship, @logo_addon2)
          end
        end
      end

    end
  end

end
