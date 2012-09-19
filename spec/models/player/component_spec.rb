require 'spec_helper'

describe Player::Component, :fog_mock do
  let(:attributes) { {
    name: 'app',
    token: 'e'
  } }
  let(:component) { Player::Component.create(attributes) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:token) }

  it { should have_many(:versions).dependent(:destroy) }
  it { should have_many(:componentships) }
  it { should have_many(:sites).through(:componentships) }

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:token) }

    context "with an same existing component" do
      before { component }

      it { should validate_uniqueness_of(:name) }
      it { should validate_uniqueness_of(:token) }
    end
  end

  it "should have many versions" do
    zip = fixture_file('player/e.zip')
    component_version1 = Player::ComponentVersion.create(token: component.token, version: '1.0.0', zip: zip)
    component_version2 = Player::ComponentVersion.create(token: component.token, version: '2.0.0', zip: zip)
    component.versions.should eq [component_version2, component_version1]
  end

end

# == Schema Information
#
# Table name: player_components
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#
# Indexes
#
#  index_player_components_on_name   (name) UNIQUE
#  index_player_components_on_token  (token) UNIQUE
#
