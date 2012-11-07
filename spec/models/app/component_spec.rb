require 'spec_helper'

describe App::Component, :fog_mock do
  let(:attributes) { {
    name: 'app',
    token: App::Component::APP_TOKEN
  } }
  let(:component) { App::Component.create(attributes, as: :admin) }

  describe "Associations" do
    it { should have_many(:versions).dependent(:destroy) }

    describe "sites", :focus do
      it "returns sites from App::Design" do
      # it "returns sites from AddonPlan && App::Design" do
        site_with_app_design = create(:site)
        app_design = create(:app_design, component: component)
        create(:billable_item, site: site_with_app_design, item: app_design)
        app_custom_design = create(:app_design)

        # site_with_app_plugin = create(:site)
        # addon = create(:addon)
        # app_plugin_without_design = create(:app_plugin, addon: addon, component: component, design: nil)
        # addon_plan = create(:addon_plan, addon: addon)
        # create(:billable_item, site: site_with_app_plugin, item: addon_plan)

        # site_with_app_plugin_with_custom_design = create(:site)
        # addon_with_custom_design = create(:addon)
        # app_plugin_without_design = create(:app_plugin, addon: addon_with_custom_design, component: component, design: app_custom_design)
        # addon_plan_with_custom_design = create(:addon_plan, addon: addon_with_custom_design)
        # create(:billable_item, site: site_with_app_plugin_with_custom_design, item: addon_plan_with_custom_design)

        component.sites.should eq([
          site_with_app_design,
          # site_with_app_plugin
        ])
      end
    end
  end

  describe "Scopes" do
    describe "app" do
      it "returns app component" do
        component
        App::Component.app.first.should eq(component)
      end
    end
  end

  describe "Validations" do
    [:name, :token].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
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

  describe "#app_component" do
    it "return the app component" do
      component
      App::Component.app_component.should eq(component)
    end
  end

  it "should have many versions" do
    zip = fixture_file('app/e.zip')
    component_version1 = App::ComponentVersion.create({ token: component.token, version: '1.0.0', zip: zip }, as: :admin)
    component_version2 = App::ComponentVersion.create({ token: component.token, version: '2.0.0', zip: zip }, as: :admin)

    # FUCK THIS FUCKING TEST!!!!!!!!!!
    component.reload.versions.all.should eq [component_version2, component_version1]
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

