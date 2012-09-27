class Player::ComponentVersion < ActiveRecord::Base
  belongs_to :component, class_name: 'Player::Component', foreign_key: 'player_component_id'

  attr_accessible :token, :dependencies, :version, :zip

  delegate :token, :name, to: :component

  mount_uploader :zip, Player::ComponentVersionUploader

  validates :player_component_id, presence: true, uniqueness: { scope: :version }
  validates :version, presence: true
  validates :zip, presence: true

  def token=(token)
    self.component = Player::Component.find_by_token!(token)
  end

  def to_param
    version_for_url
  end

  def version_for_url
    version.gsub /\./, '_'
  end

  def self.find_by_version!(version_for_url)
    version_string = version_for_url.gsub /_/, '.'
    where(version: version_string).first!
  end
end

# == Schema Information
#
# Table name: player_component_versions
#
#  created_at          :datetime         not null
#  dependencies        :hstore
#  id                  :integer          not null, primary key
#  player_component_id :integer
#  updated_at          :datetime         not null
#  version             :string(255)
#  zip                 :string(255)
#
# Indexes
#
#  index_component_versions_on_component_id_and_version  (player_component_id,version) UNIQUE
#

