require 'spec_helper'

describe Player::BundleVersion do
  let(:zip) { fixture_file('player/bA.zip') }
  let(:bundle) { Player::Bundle.create(
    name: 'app',
    token: 'bA'
  )}
  let(:attributes) { {
    token: bundle.token,
    version: 'bA',
    settings: "",
    zip: zip
  } }
  let(:bundle_version) { Player::BundleVersion.create(attributes) }

  it { should allow_mass_assignment_of(:token) }
  it { should allow_mass_assignment_of(:version) }
  it { should allow_mass_assignment_of(:zip) }
  it { should allow_mass_assignment_of(:settings) }

  describe "Validations" do
    it { should validate_presence_of(:player_bundle_id) }
    it { should validate_presence_of(:version) }
    it { should validate_presence_of(:zip) }

    context "with an same existing bundle_version" do
      before { bundle_version }

      it { should validate_uniqueness_of(:player_bundle_id).scoped_to(:version) }
    end
  end

  it "delegates token to bundle" do
    bundle_version.token.should eq bundle.token
  end

  it "delegates name to bundle" do
    bundle_version.name.should eq bundle.name
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

