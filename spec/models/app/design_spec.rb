require 'spec_helper'

describe App::Design do
  describe "Associations" do
    it { should belong_to(:component).class_name('App::Component') }
  end

  describe "Validations" do
    [:component, :skin_token, :name, :price, :availability].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should validate_numericality_of(:price) }

    it { should ensure_inclusion_of(:availability).in_array(%w[beta public custom]) }
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

