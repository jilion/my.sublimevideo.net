require 'spec_helper'

describe Player::ComponentVersion, :fog_mock do
  let(:zip) { fixture_file('player/e.zip') }
  let(:component) { Player::Component.create(
    name: 'app',
    token: 'e'
  )}
  let(:attributes) { {
    token: component.token,
    version: '2.0.0',
    zip: zip
  } }
  let(:component_version) { Player::ComponentVersion.create(attributes) }

  it { should belong_to(:component) }

  it { should allow_mass_assignment_of(:token) }
  it { should allow_mass_assignment_of(:version) }
  it { should allow_mass_assignment_of(:dependencies) }
  it { should allow_mass_assignment_of(:zip) }

  describe "Validations" do
    it { should validate_presence_of(:player_component_id) }
    it { should validate_presence_of(:version) }
    it { should validate_presence_of(:zip) }

    context "with an same existing component_version" do
      before { component_version }

      it { should validate_uniqueness_of(:player_component_id).scoped_to(:version) }
    end
  end

  it "delegates token to component" do
    component_version.token.should eq component.token
  end

  it "delegates name to component" do
    component_version.name.should eq component.name
  end

  it "overwrites to_param" do
    component_version.to_param.should eq '2_0_0'
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
