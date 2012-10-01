require 'spec_helper'

describe Player::Componentship do
  let(:addon) { create(:addon) }
  let(:component) { Player::Component.create(
    name: 'app',
    token: 'e'
  )}
  let(:attributes) { {
    addon_id: addon.id,
    player_component_id: component.id,
  } }
  let(:componentship) { Player::Componentship.create(attributes) }

  describe "Associations" do
    it { should belong_to(:component) }
    it { should belong_to(:addon) }
    it { should have_many(:sites).through(:addon) }
  end

  it { should allow_mass_assignment_of(:addon_id) }
  it { should allow_mass_assignment_of(:player_component_id) }

  describe "Validations" do
    it { should validate_presence_of(:addon_id) }
    it { should validate_presence_of(:player_component_id) }
    it { should validate_uniqueness_of(:addon_id).scoped_to(:player_component_id) }
  end
end

# == Schema Information
#
# Table name: player_componentships
#
#  addon_id            :integer
#  created_at          :datetime         not null
#  id                  :integer          not null, primary key
#  player_component_id :integer
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_player_componentships_on_addon_id_and_player_component_id  (addon_id,player_component_id) UNIQUE
#  index_player_componentships_on_player_component_id               (player_component_id)
#

