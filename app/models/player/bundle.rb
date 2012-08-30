# TODO
# Remove version_tags

class Player::Bundle < ActiveRecord::Base
  attr_accessible :name, :token, :version_tags

  serialize :version_tags, ActiveRecord::Coders::Hstore

  has_many :versions,
    class_name: 'Player::BundleVersion',
    foreign_key: 'player_bundle_id',
    dependent: :destroy,
    order: 'version desc'
  has_many :bundleships,
    class_name: 'Player::Bundleship',
    foreign_key: 'player_bundle_id',
    dependent: :destroy
  has_many :sites, through: :bundleships

  validates :name, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true

  # Avoiding whole hash overwrite
  def version_tags=(hash)
    write_attribute :version_tags, (version_tags || {}).merge(hash)
  end

  def version_tags
    read_attribute(:version_tags) || {}
  end

  def tagged_versions
    {
      'alpha' => nil,
      'beta' => nil,
      'stable' => nil
    }.tap do |hash|
      version_tags.sort.each do |tag_name, version|
        hash[tag_name] = versions.find_by_version(version)
      end
    end
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

