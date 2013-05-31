require 'spec_helper'

describe AddonPlan do
  let(:site) { create(:site) }
  let(:addon) { create(:addon) }
  let(:addon_plan1) { create(:addon_plan, addon: addon, availability: 'public') }
  let(:addon_plan2) { create(:addon_plan, addon: addon, availability: 'hidden') }
  let(:addon_plan3) { create(:addon_plan, addon: addon, availability: 'custom') }

  describe 'Associations' do
    it { should belong_to(:addon) }
    it { should have_many(:components).through(:addon) }
    it { should have_many(:billable_items) }
    it { should have_many(:sites).through(:billable_items) }
  end

  describe 'Validations' do
    [:addon, :name, :price, :availability, :required_stage, :stable_at].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should ensure_inclusion_of(:required_stage).in_array(::Stage.stages) }
    it { should ensure_inclusion_of(:availability).in_array(%w[hidden public custom]) }

    it { should validate_numericality_of(:price) }
  end

  describe '.free_addon_plans' do
    before do
      create(:addon_plan, price: 999, stable_at: nil)
      create(:addon_plan, availability: 'custom', stable_at: Time.now, price: 999)
      @addon_plan1 = create(:addon_plan, availability: 'public', price: 0)
      @addon_plan2 = create(:addon_plan, availability: 'hidden', price: 0)
      create(:addon_plan, availability: 'custom', price: 0)
    end

    it 'returns a subscriptions hash with all the free addon plans' do
      described_class.free_addon_plans.should =~ [@addon_plan1, @addon_plan2]
    end

    it 'returns a subscriptions hash with all the free addon plans minus the one for which the add-on should be rejected' do
      described_class.free_addon_plans(reject: [@addon_plan1.addon_name]).should =~ [@addon_plan2]
    end
  end

  describe '.get' do
    before do
      @addon_plan = create(:addon_plan, name: 'bar', addon: create(:addon, name: 'foo'))
    end

    it { described_class.get('foo', 'bar').should eq @addon_plan }
  end

  describe '#addon_name' do
    subject { addon_plan1 }
    its(:addon_name) { should eq addon_plan1.addon.name }
  end

  describe '#available_for_subscription?' do
    before do
      create(:billable_item, site: site, item: addon_plan1, state: 'sponsored')
    end

    it { create(:addon_plan, availability: 'hidden').available_for_subscription?(site).should be_false }
    it { create(:addon_plan, availability: 'public').available_for_subscription?(site).should be_true }
    it { addon_plan1.available_for_subscription?(site).should be_true }
    it { addon_plan2.available_for_subscription?(site).should be_false }
    it { addon_plan3.available_for_subscription?(site).should be_false }

    context 'site has a billable item for this addon plan' do
      before { create(:billable_item, item: addon_plan3, site: site) }

      it { addon_plan3.available_for_subscription?(site).should be_true }
    end
  end
end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id       :integer          not null
#  availability   :string(255)      not null
#  created_at     :datetime         not null
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  price          :integer          not null
#  required_stage :string(255)      default("stable"), not null
#  stable_at      :datetime
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

