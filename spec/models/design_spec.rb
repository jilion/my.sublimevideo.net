require 'spec_helper'

describe Design do
  describe 'Associations' do
    it { should have_many(:billable_items) }
    it { should have_many(:sites).through(:billable_items) }
  end

  describe 'Validations' do
    it { should validate_numericality_of(:price) }

    it { should ensure_inclusion_of(:required_stage).in_array(::Stage.stages) }
    it { should ensure_inclusion_of(:availability).in_array(%w[public custom]) }
  end

  describe '.custom' do
    before do
      @public = create(:design, availability: 'public')
      @custom = create(:design, availability: 'custom')
    end

    it { described_class.custom.should eq [@custom] }
  end

  describe '.paid' do
    before do
      @free = create(:design, price: 0)
      @paid = create(:design, price: 99)
    end

    it { described_class.paid.should eq [@paid] }
  end

  describe '#available_for_subscription?' do
    let(:site) { create(:site) }
    let(:custom_design) { create(:design, availability: 'custom') }

    it { create(:design, availability: 'public').available_for_subscription?(site).should be_true }
    it { custom_design.available_for_subscription?(site).should be_false }

    context 'site has a billable item for this design' do
      before { create(:billable_item, item: custom_design, site: site) }

      it { custom_design.available_for_subscription?(site).should be_true }
    end
  end
end

# == Schema Information
#
# Table name: designs
#
#  app_component_id :integer          not null
#  availability     :string(255)      not null
#  created_at       :datetime
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  price            :integer          not null
#  required_stage   :string(255)      default("stable"), not null
#  skin_mod         :string(255)
#  skin_token       :string(255)      not null
#  stable_at        :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_designs_on_name        (name) UNIQUE
#  index_designs_on_skin_token  (skin_token) UNIQUE
#

