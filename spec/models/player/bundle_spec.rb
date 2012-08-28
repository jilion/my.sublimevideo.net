require 'spec_helper'

describe Player::Bundle, :fog_mock do
  let(:attributes) { {
    name: 'app',
    token: 'e',
    version_tags: {
      # hstore keys are strings
      'alpha'  => '2.0.0-alpha.5',
      'beta'   => '2.0.0-alpha.1',
      'stable' => '1.5.3'
    }
  } }
  let(:bundle) { Player::Bundle.create(attributes) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:token) }

  it { should have_many(:versions).dependent(:destroy) }
  it { should have_many(:bundleships) }
  it { should have_many(:sites).through(:bundleships) }

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:token) }

    context "with an same existing bundle" do
      before { bundle }

      it { should validate_uniqueness_of(:name) }
      it { should validate_uniqueness_of(:token) }
    end
  end

  describe "version_tags" do
    it "return version_tags hash" do
      bundle.version_tags.should eq attributes[:version_tags]
    end

    it "return empty hash when not set" do
      Player::Bundle.new().version_tags.should eq({})
    end

    it "merge new hash with existing version_tags hash" do
      new_version_tags = { 'alpha' => '3.0.0' }
      bundle.update_attributes(version_tags: new_version_tags)
      bundle.version_tags.should eq attributes[:version_tags].merge(new_version_tags)
    end
  end

  it "overwrites to_param" do
    bundle.to_param.should eq bundle.token
  end

  it "should have many versions" do
    zip = fixture_file('player/e.zip')
    bundle_version1 = Player::BundleVersion.create(token: bundle.token, version: '1.0.0', zip: zip)
    bundle_version2 = Player::BundleVersion.create(token: bundle.token, version: '2.0.0', zip: zip)
    bundle.versions.should eq [bundle_version2, bundle_version1]
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

