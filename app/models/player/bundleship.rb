class Player::Bundleship < ActiveRecord::Base
  belongs_to :site
  belongs_to :bundle, class_name: 'Player::Bundle', foreign_key: 'player_bundle_id'

  attr_accessible :site_token, :bundle_token, :version_tag

  validates :site_id, presence: true, uniqueness: { scope: :player_bundle_id }
  validates :player_bundle_id, presence: true
  validates :version_tag, presence: true

  def site_token=(token)
    self.site = Site.find_by_token!(token)
  end

  def bundle_token=(token)
    self.bundle = Player::Bundle.find_by_token!(token)
  end

end

# == Schema Information
#
# Table name: player_bundleships
#
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  player_bundle_id :integer
#  site_id          :integer
#  updated_at       :datetime         not null
#  version_tag      :string(255)
#
# Indexes
#
#  index_player_bundleships_on_player_bundle_id  (player_bundle_id)
#  index_player_bundleships_on_site_id           (site_id)
#

