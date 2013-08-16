require 'spec_helper'

describe App::ComponentVersion, :fog_mock do
  let(:bucket) { S3Wrapper.buckets[:sublimevideo] }
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

    it "has empty hash dependencies by default" do
      attributes.delete(:dependencies)
      App::ComponentVersion.create(attributes, as: :admin).dependencies.should eq({})
    end
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

      it { should validate_uniqueness_of(:version).all_to(:app_component_id) }
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

  describe "#stage" do
    it "uses Stage.version_stage method" do
      build(:app_component_version, version: '1.0.0').stage.should eq 'stable'
    end
  end

  describe "#component_id" do
    it "returns app_component_id" do
      component_version.component_id.should eq component.id
    end
  end

  describe "#solve_version" do
    it "returns Solve::Version instance" do
      build(:app_component_version, version: '1.0.0').solve_version.should eq Solve::Version.new('1.0.0')
    end
  end

  describe "#destroy" do
    before { component_version }

    it "doesn't removes zip content" do
      prefix = "c/#{component.token}/#{component_version.version}/"
      S3Wrapper.fog_connection.directories.get(bucket, prefix: prefix).files.should have(4).files
      App::ComponentVersion.find(component_version).destroy
      S3Wrapper.fog_connection.directories.get(bucket, prefix: prefix).files.should have(4).files
    end
  end

end

# == Schema Information
#
# Table name: app_component_versions
#
#  app_component_id :integer
#  created_at       :datetime         not null
#  deleted_at       :datetime
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

