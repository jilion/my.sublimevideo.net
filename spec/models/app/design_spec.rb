require 'spec_helper'

describe App::Design do
  describe 'Associations' do
    it { should belong_to(:component).class_name('App::Component') }
    it { should have_many(:billable_items) }
  end

  describe 'Validations' do
    [:component, :skin_token, :name, :price, :availability].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should validate_numericality_of(:price) }

    it { should ensure_inclusion_of(:availability).in_array(%w[public custom]) }
  end

  describe '#available?' do
    let(:site) { create(:site) }
    let(:custom_app_design) { create(:app_design, availability: 'custom') }

    it { create(:app_design, availability: 'public').available?(site).should be_true }
    it { custom_app_design.available?(site).should be_false }

    context 'site has a billable item for this design' do
      before { create(:billable_item, item: custom_app_design, site: site) }

      it { custom_app_design.available?(site).should be_true }
    end
  end

  describe '#beta?' do
    before do
      @stable_component = create(:app_component)
      create(:app_component_version, component: @stable_component, version: '1.1.1-beta')
      create(:app_component_version, component: @stable_component, version: '1.1.2')
      @beta_component = create(:app_component)
      create(:app_component_version, component: @beta_component, version: '1.2.2')
      create(:app_component_version, component: @beta_component, version: '1.2.3-beta')

      @app_design_1 = create(:app_design, component: @stable_component)
      @app_design_2 = create(:app_design, component: @beta_component)
    end

    it { @app_design_1.should_not be_beta }
    it { @app_design_2.should be_beta }
  end

end

# == Schema Information
#
# Table name: app_designs
#
#  app_component_id :integer          not null
#  availability     :string(255)      not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  price            :integer          not null
#  skin_token       :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#

