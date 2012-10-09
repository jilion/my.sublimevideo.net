require 'spec_helper'

describe Addon do
  describe 'Associations' do
    it { should have_many(:plans).class_name('AddonPlan') }
    it { should have_many(:plugins).class_name('App::Plugin') }
    it { should have_many(:components).through(:plugins) }
  end

  describe 'Validations' do
    [:name, :design_dependent, :version, :context].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
    # it { should ensure_inclusion_of(:design_dependent).in_array([true, false]) }
    it { should ensure_inclusion_of(:version).in_array(%w[stable beta]) }
  end

  context 'Factory' do
    subject { create(:addon) }

    its(:name)    { should be_present }
    its(:context) { should eq [] }

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

  describe '#beta?' do
    it { build(:addon, version: 'stable').should_not be_beta }
    it { build(:addon, version: 'beta').should be_beta }
  end

end

# == Schema Information
#
# Table name: addons
#
#  context          :text             not null
#  created_at       :datetime         not null
#  design_dependent :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#  version          :string(255)      default("stable"), not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

