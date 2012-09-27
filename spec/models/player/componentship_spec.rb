require 'spec_helper'

describe Player::Componentship do
  # let(:addon) { create(:addon) }
  # let(:component) { Player::Component.create(
  #   name: 'app',
  #   token: 'e'
  # )}
  # let(:attributes) { {
  #   addon_id: addon.id,
  #   player_component_id: component.id,
  # } }
  # let(:componentship) { Player::Componentship.create(attributes) }

  # it { should belong_to(:component) }
  # it { should belong_to(:addon) }

  # it { should allow_mass_assignment_of(:addon_id) }
  # it { should allow_mass_assignment_of(:player_component_id) }

  # describe "Validations" do
  #   it { should validate_presence_of(:addon_id) }
  #   it { should validate_presence_of(:player_component_id) }

  #   context "with an same existing component_version" do
  #     before { componentship }

  #     it { should validate_uniqueness_of(:addon_id).scoped_to(:player_component_id) }
  #   end
  # end
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
#  index_player_componentships_on_addon_id             (addon_id)
#  index_player_componentships_on_player_component_id  (player_component_id)
#

