require 'spec_helper'

describe AddonPlan do
  describe 'Associations' do
    it { should belong_to(:addon) }
    it { should have_many(:components).through(:addon) }
  end

  describe 'Validations' do
    [:addon, :name, :price, :availability, :required_stage].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should ensure_inclusion_of(:required_stage).in_array(%w[alpha beta stable]) }
    it { should ensure_inclusion_of(:availability).in_array(%w[hidden public custom]) }

    it { should validate_numericality_of(:price) }
  end

  describe '#available?' do
    let(:site) { create(:site) }
    let(:custom_addon_plan) { create(:addon_plan, availability: 'custom') }

    it { create(:addon_plan, availability: 'hidden').available?(site).should be_false }
    it { create(:addon_plan, availability: 'public').available?(site).should be_true }
    it { custom_addon_plan.available?(site).should be_false }

    context 'site has a billable item for this addon plan' do
      before { create(:billable_item, item: custom_addon_plan, site: site) }

      it { custom_addon_plan.available?(site).should be_true }
    end
  end

  describe 'Scopes' do
    before do
      create(:addon_plan, addon: create(:addon, public_at: nil), price: 999)
      @addon_plan1 = create(:addon_plan, addon: create(:addon, public_at: Time.now), price: 0)
      @addon_plan2 = create(:addon_plan, addon: create(:addon, public_at: Time.now), price: 999)
    end

    describe '.paid' do
      it { described_class.paid.should =~ [@addon_plan2] }
    end
  end

  describe '#get' do
    before do
      @addon_plan = create(:addon_plan, name: 'bar', addon: create(:addon, name: 'foo'))
    end

    it { described_class.get('foo', 'bar').should eq @addon_plan }
  end

  describe '#beta?' do
    context 'addon is beta' do
      before do
        @addon = create(:addon, design_dependent: false, public_at: nil)
        @addon_plan = create(:addon_plan, addon: @addon)
      end

      it { @addon_plan.should be_beta }
    end
    context 'addon is stable' do
      before do
        @addon = create(:addon, design_dependent: false, public_at: Time.now)
        @addon_plan = create(:addon_plan, addon: @addon)
      end

      it { @addon_plan.should_not be_beta }
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
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

