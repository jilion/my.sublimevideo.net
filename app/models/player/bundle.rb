class Player::Bundle < ActiveRecord::Base
  attr_accessible :name, :token, :version_tags

  serialize :version_tags, ActiveRecord::Coders::Hstore

  has_many :versions, class_name: 'Player::BundleVersion', foreign_key: 'player_bundle_id'

  validates :name, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true

  # Avoiding whole hash overwrite
  def version_tags=(hash)
    write_attribute :version_tags, (version_tags || {}).merge(hash)
  end

  def to_param
    token
  end
end

# == Schema Information
#
# Table name: player_bundles
#
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  name         :string(255)
#  token        :string(255)
#  updated_at   :datetime         not null
#  version_tags :hstore
#
# Indexes
#
#  index_player_bundles_on_name   (name) UNIQUE
#  index_player_bundles_on_token  (token) UNIQUE
#

