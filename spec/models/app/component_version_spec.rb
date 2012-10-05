require 'spec_helper'

describe App::ComponentVersion, :fog_mock do
  let(:zip) { fixture_file('player/e.zip') }
  let(:component) { App::Component.create({ name: 'app', token: 'e' }, as: :admin) }
  let(:attributes) { {
    token: component.token,
    version: '2.0.0',
    zip: zip
  } }
  let(:component_version) { App::ComponentVersion.create(attributes, as: :admin) }

  it { should belong_to(:component) }

  describe "Validations" do
    [:component, :token, :version, :dependencies, :zip].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    [:component, :version, :zip].each do |attr|
      it { should validate_presence_of(attr) }
    end

    context "with an same existing component_version" do
      before { component_version }

      it { should validate_uniqueness_of(:version).scoped_to(:app_component_id) }
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
# Table name: app_component_versions
#
#  app_component_id :integer
#  created_at       :datetime         not null
#  dependencies     :hstore
#  id               :integer          not null, primary key
#  updated_at       :datetime         not null
#  version          :string(255)
#  zip              :string(255)
#
# Indexes
#
#  index_component_versions_on_component_id_and_version  (app_component_id,version) UNIQUE
#

