require 'spec_helper'

describe BillableItem do
  let(:site)  { create(:site) }

  describe 'Associations' do
    it { should belong_to :item }
    it { should belong_to :site }
  end

  describe 'Validations' do
    [:item, :site, :state].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    [:item, :site, :state].each do |attr|
      it { should validate_presence_of(attr) }
    end

    it { should ensure_inclusion_of(:state).in_array(%w[subscribed sponsored suspended]) }
  end

  context 'Factory' do
    subject { build(:addon_plan_billable_item) }

    its(:state) { should eq 'subscribed' }
    its(:site)  { should be_present }
    its(:item)  { should be_present }

    it { should be_valid }
  end

  describe 'Callbacks', :addons do
    describe 'on create' do
      %w[beta trial subscribed sponsored suspended].each do |new_state|
        it "create a BillableItemActivity record with the #{new_state} state" do
          expect {
            create(:billable_item, site: site, item: @logo_addon_plan_1, state: new_state)
          }.to change(BillableItemActivity, :count).by(1)
          last_billable_item_activity = BillableItemActivity.last

          last_billable_item_activity.item.should eq @logo_addon_plan_1
          last_billable_item_activity.state.should eq new_state
        end

        it "increments metrics with #{new_state}" do
          # Librato.should_receive(:increment).with("addons.#{new_state}", source: "#{@logo_addon_plan_1.addon.name}-#{@logo_addon_plan_1.name}")
          Librato.should_receive(:increment).with('addons.events', source: new_state)

          create(:billable_item, site: site, item: @logo_addon_plan_1, state: new_state)
        end
      end
    end

    describe 'on update' do
      let(:billable_item) { create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'beta') }

      %w[trial subscribed sponsored suspended].each do |new_state|
        it "create a BillableItemActivity record with the #{new_state} state" do
        billable_item # eager load!
          expect {
            billable_item.update_attributes({ state: new_state }, without_protection: true)
          }.to change(BillableItemActivity, :count).by(1)
          last_billable_item_activity = BillableItemActivity.last

          last_billable_item_activity.item.should eq @logo_addon_plan_1
          last_billable_item_activity.state.should eq new_state
        end

        it "increments metrics with #{new_state}" do
          # Librato.should_receive(:increment).with("addons.#{new_state}", source: "#{@logo_addon_plan_1.addon.name}-#{@logo_addon_plan_1.name}")
          Librato.should_receive(:increment).with('addons.events', source: new_state)

          create(:billable_item, site: site, item: @logo_addon_plan_1, state: new_state)
        end
      end
    end

    describe 'on delete' do
      let(:billable_item) { create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'beta') }

      it "create a BillableItemActivity record with the 'canceled' state" do
        billable_item # eager load!
        expect {
          billable_item.destroy
        }.to change(BillableItemActivity, :count).by(1)
        last_billable_item_activity = BillableItemActivity.last

        last_billable_item_activity.item.should eq @logo_addon_plan_1
        last_billable_item_activity.state.should eq 'canceled'
      end

      it "increments metrics with canceled" do
        billable_item # eager load!
        # Librato.should_receive(:increment).with('addons.canceled', source: "#{@logo_addon_plan_1.addon.name}-#{@logo_addon_plan_1.name}")
        Librato.should_receive(:increment).with('addons.events', source: 'canceled')

        billable_item.destroy
      end
    end
  end

  describe 'Scopes', :addons do
    let(:site) { create(:site) }
    before do
      @billable_item1 = create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'subscribed')
      @billable_item2 = create(:billable_item, site: site, item: @logo_addon_plan_2, state: 'subscribed')
      @billable_item3 = create(:billable_item, site: site, item: @stats_addon_plan_1, state: 'sponsored')
      @billable_item4 = create(:billable_item, site: site, item: @support_addon_plan_2, state: 'suspended')
      @billable_item5 = create(:billable_item, site: site, item: @classic_design, state: 'subscribed')

      addon_plan = create(:addon_plan, addon: create(:addon), price: 9999999, stable_at: nil)
      @billable_item6 = create(:billable_item, site: site, item: addon_plan, state: 'subscribed')
    end

    describe '.active addons' do
      it { described_class.active.should =~ [@billable_item1, @billable_item2, @billable_item3, @billable_item5, @billable_item6] }
    end

    describe '.subscribed addons' do
      it { described_class.subscribed.should =~ [@billable_item1, @billable_item2, @billable_item5, @billable_item6] }
    end

    describe '.paid addons' do
      it { described_class.paid.should =~ [@billable_item2, @billable_item4] }
    end
  end

  describe '#active?' do
    %w[suspended].each do |state|
      it "is active when in the #{state} state" do
        build(:addon_plan_billable_item, state: state).should_not be_active
      end
    end

    %w[subscribed sponsored].each do |state|
      it "isn't active when in the #{state} state" do
        build(:addon_plan_billable_item, state: state).should be_active
      end
    end
  end

end

# == Schema Information
#
# Table name: billable_items
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  site_id    :integer          not null
#  state      :string(255)      not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_billable_items_on_item_type_and_item_id              (item_type,item_id)
#  index_billable_items_on_item_type_and_item_id_and_site_id  (item_type,item_id,site_id) UNIQUE
#  index_billable_items_on_site_id                            (site_id)
#

