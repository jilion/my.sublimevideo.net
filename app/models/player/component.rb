class Player::Component < ActiveRecord::Base
  attr_accessible :name, :token

  has_many :versions,
    class_name: 'Player::ComponentVersion',
    foreign_key: 'player_component_id',
    dependent: :destroy,
    order: 'version desc'
  has_many :componentships,
    class_name: 'Player::Componentship',
    foreign_key: 'player_component_id',
    dependent: :destroy
  has_many :sites, through: :componentships

  validates :name, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true

  def to_param
    token
  end
end

# == Schema Information
#
# Table name: player_components
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#
# Indexes
#
#  index_player_components_on_name   (name) UNIQUE
#  index_player_components_on_token  (token) UNIQUE
#

