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

  describe 'Scopes', :addons do
    let(:site) { create(:site) }
    before do
      @billable_item1 = create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'subscribed')
      @billable_item2 = create(:billable_item, site: site, item: @logo_addon_plan_2, state: 'subscribed')
      @billable_item3 = create(:billable_item, site: site, item: @stats_addon_plan_1, state: 'sponsored')
      @billable_item4 = create(:billable_item, site: site, item: @support_addon_plan_2, state: 'suspended')
      @billable_item5 = create(:billable_item, site: site, item: @classic_design, state: 'subscribed')

      addon_plan = create(:addon_plan, addon: create(:addon, public_at: nil), price: 9999999)
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

