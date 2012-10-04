require 'spec_helper'

describe App::Component, :fog_mock do
  let(:attributes) { {
    name: 'app',
    token: 'e'
  } }
  let(:component) { App::Component.create(attributes) }

  describe "Associations" do
    it { should have_many(:versions).dependent(:destroy) }
    # it { should have_many(:sites).through(:componentships) }
  end

  describe "Validations" do
    [:name, :token].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    [:name, :token].each do |attr|
      it { should validate_presence_of(attr) }
    end

    context "with an same existing component" do
      before { component }

      [:name, :token].each do |attr|
        it { should validate_uniqueness_of(attr) }
      end
    end
  end

  it "should have many versions" do
    zip = fixture_file('player/e.zip')
    component_version1 = App::ComponentVersion.create(token: component.token, version: '1.0.0', zip: zip)
    component_version2 = App::ComponentVersion.create(token: component.token, version: '2.0.0', zip: zip)
    component.versions.should eq [component_version2, component_version1]
  end

end

# == Schema Information
#
# Table name: app_components
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

