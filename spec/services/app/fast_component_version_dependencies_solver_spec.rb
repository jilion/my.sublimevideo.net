require 'fast_spec_helper'

require 'models/stage'
require 'services/app/fast_component_version_dependencies_solver'

App = Module.new unless defined?(App)
Site = Class.new unless defined?(Site)
App::Component = Struct.new(:name, :token) unless defined?(App::Component)
App::ComponentVersion = Struct.new(:version, :component, :dependencies) do
  def stage
    Stage.version_stage(version)
  end
end unless defined?(App::ComponentVersion)

def create_component(name, token)
  if defined?(ActiveRecord)
    App::Component.new(name: name, token: token)
  else
    App::Component.new(name, token)
  end
end

def create_component_version(version, component)
  if defined?(ActiveRecord)
    App::ComponentVersion.new(version: version, component: component, dependencies: {})
  else
    App::ComponentVersion.new(version, component, {})
  end
end

describe App::FastComponentVersionDependenciesSolver do
  let(:site) { Site.new }

  let(:twit_component)     { create_component('twit', 'twit') }
  let(:twit_component_200) { create_component_version('2.0.0', twit_component) }
  let(:twit_component_200beta1) { create_component_version('2.0.0-beta.1', twit_component) }
  let(:twit_component_200alpha1) { create_component_version('2.0.0-alpha.1', twit_component) }

  let(:app_component)           { create_component('app', 'a') }
  let(:app_component_200alpha1) { create_component_version('2.0.0-alpha.1', app_component) }
  let(:app_component_200beta1)  { create_component_version('2.0.0-beta.1', app_component) }
  let(:app_component_200)       { create_component_version('2.0.0', app_component) }

  let(:classic_design) { double(name: 'classic') }
  let(:light_design) { double(name: 'light') }
  let(:flat_design) { double(name: 'flat') }
  let(:twit_design) { double(name: 'twit', component: twit_component) }

  describe '.components_dependencies' do
    before do
      App::Component.stub(:app_component) { app_component }
    end

    context 'with stage is stable' do
      before do
        expect_any_instance_of(described_class).to receive(:_current_component_version).with(app_component) { app_component_200 }
      end

      context 'with no custom design components' do
        before { site.stub(:designs) { [classic_design] } }

        it 'depends only on app' do
          described_class.components_dependencies(site, 'stable').should eq('a' => '2.0.0')
        end
      end

      context 'with a custom design component' do
        before do
          site.stub(:designs) { [twit_design] }
          twit_component.stub(:versions_for_stage).with('stable')  { [twit_component_200] }
          twit_component_200.stub(:dependencies) { {} }
          expect_any_instance_of(described_class).to receive(:_current_component_version).with(twit_component) { twit_component_200 }
        end

        it 'depends on app and design component' do
          described_class.components_dependencies(site, 'stable').should eq('a' => '2.0.0', 'twit' => '2.0.0')
        end
      end
    end

    context 'with stage is beta' do
      before do
        expect_any_instance_of(described_class).to receive(:_current_component_version).with(app_component) { app_component_200beta1 }
      end

      context 'with no custom design components' do
        before { site.stub(:designs) { [classic_design] } }

        it 'depends only on app' do
          described_class.components_dependencies(site, 'beta').should eq('a' => '2.0.0-beta.1')
        end
      end

      context 'with a custom design component without a beta version' do
        before do
          site.stub(:designs) { [twit_design] }
          twit_component.stub(:versions_for_stage).with('beta')  { [] }
          expect_any_instance_of(described_class).to_not receive(:_current_component_version).with(twit_component)
        end

        it 'depends only on app' do
          described_class.components_dependencies(site, 'beta').should eq('a' => '2.0.0-beta.1')
        end
      end

      context 'with a custom design component with a beta version' do
        before do
          site.stub(:designs) { [twit_design] }
          twit_component.stub(:versions_for_stage).with('beta')  { [twit_component_200beta1] }
          twit_component_200beta1.stub(:dependencies) { {} }
          expect_any_instance_of(described_class).to receive(:_current_component_version).with(twit_component) { twit_component_200beta1 }
        end

        it 'depends on app and design component' do
          described_class.components_dependencies(site, 'beta').should eq('a' => '2.0.0-beta.1', 'twit' => '2.0.0-beta.1')
        end
      end
    end

    context 'with stage is alpha' do
      before do
        expect_any_instance_of(described_class).to receive(:_current_component_version).with(app_component) { app_component_200alpha1 }
      end

      context 'with no custom design components' do
        before { site.stub(:designs) { [classic_design] } }

        it 'depends only on app' do
          described_class.components_dependencies(site, 'alpha').should eq('a' => '2.0.0-alpha.1')
        end
      end

      context 'with a custom design component without a alpha version' do
        before do
          site.stub(:designs) { [twit_design] }
          twit_component.stub(:versions_for_stage).with('alpha')  { [] }
          expect_any_instance_of(described_class).to_not receive(:_current_component_version).with(twit_component)
        end

        it 'depends only on app' do
          described_class.components_dependencies(site, 'alpha').should eq('a' => '2.0.0-alpha.1')
        end
      end

      context 'with a custom design component with a alpha version' do
        before do
          site.stub(:designs) { [twit_design] }
          twit_component.stub(:versions_for_stage).with('alpha')  { [twit_component_200alpha1] }
          twit_component_200alpha1.stub(:dependencies) { {} }
          expect_any_instance_of(described_class).to receive(:_current_component_version).with(twit_component) { twit_component_200alpha1 }
        end

        it 'depends on app and design component' do
          described_class.components_dependencies(site, 'alpha').should eq('a' => '2.0.0-alpha.1', 'twit' => '2.0.0-alpha.1')
        end
      end
    end

  end
end
