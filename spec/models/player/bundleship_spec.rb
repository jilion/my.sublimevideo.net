require 'spec_helper'

describe Player::Bundleship do
  let(:site) { create(:site) }
  let(:bundle) { Player::Bundle.create(
    name: 'app',
    token: 'e'
  )}
  let(:attributes) { {
    site_token: site.token,
    bundle_token: bundle.token,
    version_tag: "stable"
  } }
  let(:bundleship) { Player::Bundleship.create(attributes) }

  it { should belong_to(:bundle) }
  it { should belong_to(:site) }

  it { should allow_mass_assignment_of(:site_token) }
  it { should allow_mass_assignment_of(:bundle_token) }
  it { should allow_mass_assignment_of(:version_tag) }

  describe "Validations" do
    it { should validate_presence_of(:site_id) }
    it { should validate_presence_of(:player_bundle_id) }
    it { should validate_presence_of(:version_tag) }

    context "with an same existing bundle_version" do
      before { bundleship }

      it { should validate_uniqueness_of(:site_id).scoped_to(:player_bundle_id) }
    end
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

