require 'spec_helper'

describe App::Design do
  describe 'Associations' do
    it { should belong_to(:component).class_name('App::Component') }
    it { should have_many(:billable_items) }
  end

  describe 'Validations' do
    [:component, :skin_token, :name, :price, :availability, :required_stage, :public_at].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should validate_numericality_of(:price) }

    it { should ensure_inclusion_of(:required_stage).in_array(::Stage::STAGES) }
    it { should ensure_inclusion_of(:availability).in_array(%w[public custom]) }
  end

  describe '.custom' do
    before do
      @public = create(:app_design, availability: 'public')
      @custom = create(:app_design, availability: 'custom')
    end

    it { described_class.custom.all.should eq [@custom] }
  end

  describe '.paid' do
    before do
      @free = create(:app_design, price: 0)
      @paid = create(:app_design, price: 99)
    end

    it { described_class.paid.all.should eq [@paid] }
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
    it { build(:app_design, public_at: nil).should be_beta }
    it { build(:app_design, public_at: Time.now).should_not be_beta }
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
#  public_at        :datetime
#  required_stage   :string(255)      default("stable"), not null
#  skin_token       :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#

