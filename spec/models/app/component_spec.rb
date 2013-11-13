require 'spec_helper'

describe App::Component, :fog_mock do
  let(:attributes) { {
    name: 'app',
    token: App::Component::APP_TOKEN
  } }
  let(:component) { App::Component.create(attributes) }

  describe "Associations" do
    it { should have_many(:versions).dependent(:destroy) }

    describe 'versions' do
      before do
        @version1 = create(:app_component_version, component: component, version: '2.5.9-alpha.4')
        @version2 = create(:app_component_version, component: component, version: '2.5.10-alpha')
      end

      it 'returns the version ordered by created_at desc' do
        expect(component.versions).to eq [@version2, @version1]
      end
    end

    describe "sites" do
      it "returns sites from Design" do
        site_with_design = create(:site)
        design = create(:design, component: component)
        create(:billable_item, site: site_with_design, item: design)
        app_custom_design = create(:design)

        expect(component.sites).to eq([
          site_with_design,
        ])
      end
    end
  end

  describe "Validations" do
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
      expect(App::Component.app_component).to eq(component)
    end
  end

  it "should have many versions" do
    zip = fixture_file('app/e.zip')
    component_version1 = App::ComponentVersion.create(token: component.token, version: '1.0.0', zip: zip)
    component_version2 = App::ComponentVersion.create(token: component.token, version: '2.0.0', zip: zip)

    # FUCK THIS FUCKING TEST!!!!!!!!!!
    expect(component.reload.versions).to eq [component_version2, component_version1]
  end

  describe '#versions_for_stage' do
   let!(:zip) { fixture_file('app/e.zip') }
   let!(:component_version_alpha)  { App::ComponentVersion.create(token: component.token, version: '1.0.0-alpha', zip: zip) }
   let!(:component_version_beta)   { App::ComponentVersion.create(token: component.token, version: '1.0.0-beta', zip: zip) }
   let!(:component_version_stable) { App::ComponentVersion.create(token: component.token, version: '1.0.0', zip: zip) }

    context 'aplha stage given' do
      it 'returns alpha version only' do
        expect(component.versions_for_stage('alpha')).to match_array([component_version_stable, component_version_beta, component_version_alpha])
      end
    end

    context 'beta stage given' do
      it 'returns beta and stable versions' do
        expect(component.versions_for_stage('beta')).to match_array([component_version_stable, component_version_beta])
      end
    end

    context 'stable stage given' do
      it 'returns alpha, beta and stable versions' do
        expect(component.versions_for_stage('stable')).to match_array([component_version_stable])
      end
    end
  end

end

# == Schema Information
#
# Table name: app_components
#
#  created_at :datetime
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime
#
# Indexes
#
#  index_app_components_on_name   (name) UNIQUE
#  index_app_components_on_token  (token) UNIQUE
#

