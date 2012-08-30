# TODO
# - settings really needed?
# - no version tag needed, use version 'tag' ex: '2.0.0-beta.1'
# app_dependency "~> 3.0.0-alpha"

class Player::BundleVersion < ActiveRecord::Base
  belongs_to :bundle, class_name: 'Player::Bundle', foreign_key: 'player_bundle_id'

  attr_accessible :token, :settings, :version, :zip

  delegate :token, :name, to: :bundle

  mount_uploader :zip, Player::BundleVersionUploader

  validates :player_bundle_id, presence: true, uniqueness: { scope: :version }
  validates :version, presence: true
  validates :zip, presence: true

  def token=(token)
    self.bundle = Player::Bundle.find_by_token!(token)
  end

  def tagged?
    bundle.version_tags.values.include?(version)
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
# Table name: player_bundle_versions
#
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  player_bundle_id :integer
#  settings         :text
#  updated_at       :datetime         not null
#  version          :string(255)
#  zip              :string(255)
#
# Indexes
#
#  index_player_bundle_versions_on_player_bundle_id_and_version  (player_bundle_id,version) UNIQUE
#

