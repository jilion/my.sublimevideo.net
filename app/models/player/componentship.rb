class Player::Componentship < ActiveRecord::Base
  # attr_accessible :addon_id, :player_component_id

  # belongs_to :addon
  # belongs_to :component, class_name: 'Player::Component', foreign_key: 'player_component_id'

  # validates :addon_id, presence: true, uniqueness: { scope: :player_component_id }
  # validates :player_component_id, presence: true
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

