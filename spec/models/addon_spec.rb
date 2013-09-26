require 'spec_helper'

describe Addon do
  describe 'Associations' do
    it { should belong_to(:parent_addon).class_name('Addon') }
    it { should have_many(:plans).class_name('AddonPlan') }
    it { should have_many(:plugins).class_name('App::Plugin') }
    it { should have_many(:components).through(:plugins) }
    it { should have_many(:sites).through(:plans) }
  end

  describe 'Validations' do
    # it { should ensure_inclusion_of(:design_dependent).in_array([true, false]) }
  end

  context 'Factory' do
    subject { create(:addon) }

    its(:name) { should be_present }

    it { should be_valid }
  end

  describe '.get' do
    before do
      @logo_addon = create(:addon, name: 'logo')
    end

    it { described_class.get('logo').should eq @logo_addon }
  end

  describe '#free_plan' do
    before do
      @addon = create(:addon)
      @free_plan  = create(:addon_plan, addon: @addon, price: 0)
      @paid_plan1 = create(:addon_plan, addon: @addon, price: 995)
      @free_plan2 = create(:addon_plan, addon: @addon, price: 1995)
    end

    it { @addon.free_plan.should eq @free_plan }
  end

  describe '.with_paid_plans' do
    before do
      @addon1 = create(:addon)
      create(:addon_plan, addon: @addon1, price: 0)
      create(:addon_plan, addon: @addon1, price: 995)

      @addon2 = create(:addon)
      create(:addon_plan, addon: @addon2, price: 995)

      @addon3 = create(:addon)
      create(:addon_plan, addon: @addon3, price: 0)
    end

    it { described_class.with_paid_plans.should eq [@addon1, @addon2] }
  end

  describe '.visible' do
    before do
      @addon1 = create(:addon)
      create(:addon_plan, addon: @addon1, price: 0, availability: 'public')
      create(:addon_plan, addon: @addon1, price: 995, availability: 'custom')

      @addon2 = create(:addon)
      create(:addon_plan, addon: @addon2, price: 995, availability: 'public')

      @addon3 = create(:addon)
      create(:addon_plan, addon: @addon3, price: 0, availability: 'hidden')
    end

    it { described_class.visible.should eq [@addon1, @addon2] }
  end

  describe '.not_custom' do
    before do
      @addon1 = create(:addon)
      create(:addon_plan, addon: @addon1, price: 0, availability: 'hidden')
      create(:addon_plan, addon: @addon1, price: 995, availability: 'public')

      @addon2 = create(:addon)
      create(:addon_plan, addon: @addon2, price: 995, availability: 'hidden')

      @addon3 = create(:addon)
      create(:addon_plan, addon: @addon3, price: 0, availability: 'custom')
    end

    it { described_class.not_custom.should eq [@addon1, @addon2] }
  end

end

# == Schema Information
#
# Table name: addons
#
#  created_at       :datetime
#  design_dependent :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  kind             :string(255)
#  name             :string(255)      not null
#  parent_addon_id  :integer
#  updated_at       :datetime
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

