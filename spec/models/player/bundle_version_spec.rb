require 'spec_helper'

describe Player::BundleVersion, :fog_mock do
  let(:zip) { fixture_file('player/e.zip') }
  let(:bundle) { Player::Bundle.create(
    name: 'app',
    token: 'e'
  )}
  let(:attributes) { {
    token: bundle.token,
    version: 'e',
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

  describe "tagged?" do
    it "returns true when tagged in bundle" do
      bundle.update_attributes(version_tags: { stabe: bundle_version.version })
      bundle_version.reload
      bundle_version.should be_tagged
    end
    it "returns false when not tagged in bundle" do
      bundle_version.should_not be_tagged
    end
  end

  it "overwrites to_param" do
    bundle_version.to_param.should eq bundle_version.version
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

