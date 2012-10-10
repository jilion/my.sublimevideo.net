require 'spec_helper'

describe App::ComponentVersion, :fog_mock do
  let(:zip) { fixture_file('app/e.zip') }
  let(:component) { App::Component.create({ name: 'app', token: 'e' }, as: :admin) }
  let(:attributes) { {
    token: component.token,
    version: '2.0.0',
    dependencies: { app: "1.0.0" },
    zip: zip
  } }
  let(:component_version) { App::ComponentVersion.create(attributes, as: :admin) }

  context "Object" do
    subject { component_version }

    its(:token)        { should eq component.token }
    its(:name)         { should eq component.name }
    its(:version)      { should eq '2.0.0' }
    its(:zip)          { should be_present }
    its(:dependencies) { should eq({"app" => "1.0.0"}) }

    it { should be_valid }
  end

  describe "Associations" do
    it { should belong_to(:component) }
  end

  describe "Validations" do
    [:component, :token, :version, :dependencies, :zip].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    [:component, :zip].each do |attr|
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

  it "supports json for dependencies" do
    version = App::ComponentVersion.create(attributes.merge(dependencies: {app: "1.0.0"}.to_json), as: :admin)
    version.dependencies.should eq({"app" => "1.0.0"})
  end

  it "compares via Service::SemanticVersioning" do
    version100_aplha1 = App::ComponentVersion.new({ version: '1.0.0-alpha.1' }, as: :admin)
    version100 = App::ComponentVersion.new({ version: '1.0.0' }, as: :admin)
    version200 = App::ComponentVersion.new({ version: '2.0.0' }, as: :admin)
    version124 = App::ComponentVersion.new({ version: '1.2.4' }, as: :admin)
    version123 = App::ComponentVersion.new({ version: '1.2.3' }, as: :admin)

    [version100, version100_aplha1, version200, version124, version123].sort.should eq([
      version100_aplha1, version100, version123, version124, version200
    ])
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

