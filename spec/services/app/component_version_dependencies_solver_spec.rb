require 'fast_spec_helper'

require 'models/stage'
require 'services/app/component_version_dependencies_solver'

App = Module.new unless defined?(App)
Site = Class.new unless defined?(Site)
App::Component = Struct.new(:name, :token) unless defined?(App::Component)
App::ComponentVersion = Struct.new(:version, :component, :dependencies) do
  def stage
    Stage.version_stage(version)
  end
end unless defined?(App::ComponentVersion)

def create_app_component(name, token)
  if defined?(ActiveRecord)
    App::Component.new({ name: name, token: token }, as: :admin)
  else
    App::Component.new(name, token)
  end
end

def create_app_component_version(version, component)
  if defined?(ActiveRecord)
    App::ComponentVersion.new({ version: version, component: component }, as: :admin)
  else
    App::ComponentVersion.new(version, component)
  end
end

describe App::ComponentVersionDependenciesSolver do
  let(:site) { Site.new }

  let(:c_a)           { create_app_component('app', 'a') }
  let(:c_a_100)       { create_app_component_version('1.0.0', c_a) }
  let(:c_a_200alpha1) { create_app_component_version('2.0.0-alpha.1', c_a) }
  let(:c_a_200beta1)  { create_app_component_version('2.0.0-beta.1', c_a) }
  let(:c_a_200)       { create_app_component_version('2.0.0', c_a) }

  let(:c_c1)           { create_app_component('c1', 'c1') }
  let(:c_c1_100)       { create_app_component_version('1.0.0', c_c1) }
  let(:c_c1_110)       { create_app_component_version('1.1.0', c_c1) }
  let(:c_c1_200alpha1) { create_app_component_version('2.0.0-alpha.1', c_c1) }
  let(:c_c1_200beta1)  { create_app_component_version('2.0.0-beta.1', c_c1) }

  let(:c_c2)     { create_app_component('c2', 'c2') }
  let(:c_c2_100) { create_app_component_version('1.0.0', c_c2) }
  let(:c_c2_200) { create_app_component_version('2.0.0', c_c2) }

  let(:c_c3)     { create_app_component('c3', 'c3') }
  let(:c_c3_100) { create_app_component_version('1.0.0', c_c3) }
  let(:c_c3_200) { create_app_component_version('2.0.0', c_c3) }

  let(:c_c4)           { create_app_component('c4', 'c4') }
  let(:c_c4_100alpha1) { create_app_component_version('1.0.0-alpha.1', c_c4) }

  describe '.components_dependencies' do
    before do
      App::Component.stub(:app_component) { c_a }
      c_a_100.stub(:dependencies) { {} }
      c_a_200.stub(:dependencies) { {} }
      c_a_200beta1.stub(:dependencies) { {} }
      c_a_200alpha1.stub(:dependencies) { {} }

      c_c1_100.stub(:dependencies) { {} }
      c_c1_110.stub(:dependencies) { {} }
      c_c1_200alpha1.stub(:dependencies) { {} }
      c_c1_200beta1.stub(:dependencies) { {} }

      c_c2_100.stub(:dependencies) { {} }
      c_c2_200.stub(:dependencies) { {} }

      c_c3_100.stub(:dependencies) { {} }
      c_c3_200.stub(:dependencies) { {} }

      c_c4_100alpha1.stub(:dependencies) { {} }
    end

    context 'with stage is stable' do
      before do
        c_a.stub(:versions_for_stage).with('stable')  { [c_a_200, c_a_100] }
        c_c1.stub(:versions_for_stage).with('stable') { [c_c1_110, c_c1_100] }
        c_c2.stub(:versions_for_stage).with('stable') { [c_c2_100, c_c2_200] }
        c_c3.stub(:versions_for_stage).with('stable') { [c_c3_100, c_c3_200] }
        c_c4.stub(:versions_for_stage).with('stable') { [] }
      end

      context 'with 0 site components dependencies' do
        before { site.stub(:components) { [] } }

        it 'depends on the app bigger component version' do
          described_class.components_dependencies(site, 'stable').should eq('a' => '2.0.0')
        end
      end

      context 'with same site components dependency with no dependencies' do
        before { site.stub(:components) { [c_a] } }

        it 'depends only once on app bigger component version' do
          described_class.components_dependencies(site, 'stable').should eq('a' => '2.0.0')
        end
      end

      context 'with one other site components dependency' do
        before { site.stub(:components) { [c_c1] } }

        context 'with no dependencies' do
          it 'depends on the both bigger components versions' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '2.0.0', 'c1' => '1.1.0')
          end
        end

        context 'with app component dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } }
          end

          it 'depends on the both bigger components versions' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.1.0')
          end
        end

        context 'with app component dependency with an unexistent dependencies' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '3.0.0' } } # unexistent
          end

          it 'depends on the both bigger components versions valid' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.0.0')
          end
        end

        context 'with app component dependency and another dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            App::Component.stub(:get).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
          end

          it 'depends on all dependencies' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.1.0', 'c2' => '2.0.0')
          end
        end

        context 'with app component dependency and another dependency with version with an impossible dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            App::Component.stub(:get).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } } # impossible
          end

          it 'do not depend on the impossible dependency' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.1.0', 'c2' => '1.0.0')
          end
        end

        context 'with app component dependency and another dependency with another dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            App::Component.stub(:get).with('c2') { c_c2 }
            App::Component.stub(:get).with('c3') { c_c3 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '1.0.0', 'c3' => '1.0.0' } }
          end

          it 'depends on all dependencies' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.1.0', 'c2' => '2.0.0', 'c3' => '1.0.0')
          end
        end

        context 'with app component dependency with a new version impossible to solve' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            App::Component.stub(:get).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c2_100.stub(:dependencies) { { 'app' => '2.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } }
          end

          it 'do not depend on the new version' do
            described_class.components_dependencies(site, 'stable').should eq('a' => '1.0.0', 'c1' => '1.0.0')
          end
        end

        context 'with app component dependency impossible to solve' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            App::Component.stub(:get).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c2_100.stub(:dependencies) { { 'app' => '2.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } }
          end

          it 'raise Solve::Errors::NoSolutionError' do
            expect { described_class.components_dependencies(site, 'stable') }.to raise_error(Solve::Errors::NoSolutionError)
          end
        end
      end
    end

    context 'with stage is beta' do
      before do
        c_a.stub(:versions_for_stage).with('beta') { [c_a_200, c_a_100, c_a_200beta1] }
        c_c1.stub(:versions_for_stage).with('beta') { [c_c1_110, c_c1_100, c_c1_200beta1] }
        c_c4.stub(:versions_for_stage).with('beta') { [] }
      end

      context 'with one other site components dependency' do
        before { site.stub(:components) { [c_c1, c_c4] } }

        context 'with app component dependency and another dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_200alpha1.stub(:dependencies) { { 'app' => '2.0.0-alpha.1' } }
            c_c1_200beta1.stub(:dependencies) { { 'app' => '2.0.0-beta.1' } }
          end

          it 'depends on all beta dependencies' do
            described_class.components_dependencies(site, 'beta').should eq('a' => '2.0.0-beta.1', 'c1' => '2.0.0-beta.1')
          end
        end
      end
    end

    context 'with stage is alpha' do
      before do
        c_a.stub(:versions_for_stage).with('alpha') { [c_a_200, c_a_100, c_a_200beta1, c_a_200alpha1] }
        c_c4.stub(:versions_for_stage).with('alpha') { [c_c4_100alpha1] }
      end

      context 'with one other site components dependency' do
        before { site.stub(:components) { [c_c4] } }

        context 'with app component dependency and another dependency with another dependency' do
          before do
            App::Component.stub(:get).with('app') { c_a }
            c_c4_100alpha1.stub(:dependencies) { { 'app' => '1.0.0' } }
          end

          it 'depends on all dependencies' do
            described_class.components_dependencies(site, 'alpha').should eq('a' => '1.0.0', 'c4' => '1.0.0-alpha.1')
          end
        end
      end
    end

  end
end
