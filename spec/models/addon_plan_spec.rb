require 'spec_helper'

describe AddonPlan do
  describe 'Associations' do
    it { should belong_to(:addon) }
    it { should have_many(:components).through(:addon) }
  end

  describe 'Validations' do
    [:addon, :name, :price, :availability, :works_with_stable_app].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should ensure_inclusion_of(:availability).in_array(%w[hidden public custom]) }
    it { should ensure_inclusion_of(:works_with_stable_app).in_array([true, false]) }

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

  pending 'Scopes' do
    describe '.not_beta' do
      it { described_class.not_beta.should =~ [@free_public_addon, @public_addon, @custom_addon] }
    end

    describe '.paid' do
      it { described_class.paid.should =~ [@public_addon, @custom_addon] }
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
        # @beta_component = create(:app_component)
        # create(:app_component_version, component: @beta_component, version: '1.2.3-beta')
        @addon = create(:addon, design_dependent: false, version: 'beta')
        @addon_plan = create(:addon_plan, addon: @addon)
        # create(:app_plugin, addon: @addon, component: @beta_component)
      end

      it { @addon_plan.should be_beta }
    end
    context 'addon is stable' do
      before do
        # @beta_component = create(:app_component)
        # create(:app_component_version, component: @beta_component, version: '1.2.3-beta')
        @addon = create(:addon, design_dependent: false, version: 'stable')
        @addon_plan = create(:addon_plan, addon: @addon)
        # create(:app_plugin, addon: @addon, component: @beta_component)
      end

      it { @addon_plan.should_not be_beta }
    end

    # context 'addon is design_dependent' do
    #   before do
    #     @stable_component = create(:app_component)
    #     create(:app_component_version, component: @stable_component, version: '1.1.1-beta')
    #     create(:app_component_version, component: @stable_component, version: '1.1.2')
    #     @beta_component = create(:app_component)
    #     create(:app_component_version, component: @beta_component, version: '1.2.2')
    #     create(:app_component_version, component: @beta_component, version: '1.2.3-beta')

    #     @addon = create(:addon, design_dependent: true)
    #     @addon_plan = create(:addon_plan, addon: @addon)
    #     @app_design_1 = create(:app_design)
    #     @app_design_2 = create(:app_design)

    #     create(:app_plugin, addon: @addon, design: @app_design_1, component: @stable_component)
    #     create(:app_plugin, addon: @addon, design: @app_design_2, component: @beta_component)
    #   end

    #   it { @addon_plan.beta?(@app_design_1).should be_false }
    #   it { @addon_plan.beta?(@app_design_2).should be_true }
    # end
  end
end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id              :integer          not null
#  availability          :string(255)      not null
#  created_at            :datetime         not null
#  id                    :integer          not null, primary key
#  name                  :string(255)      not null
#  price                 :integer          not null
#  updated_at            :datetime         not null
#  works_with_stable_app :boolean          default(TRUE), not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

