require 'fast_spec_helper'

require 'services/component_version_dependencies_solver'
require 'models/stage'

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

describe ComponentVersionDependenciesSolver do
  let(:site) { Site.new }
  let(:c_a) { create_app_component('app', 'a') }
  let(:c_a_100) { create_app_component_version("1.0.0", c_a) }
  let(:c_a_200alpha1) { create_app_component_version("2.0.0-alpha.1", c_a) }
  let(:c_a_200beta1) { create_app_component_version("2.0.0-beta.1", c_a) }
  let(:c_a_200) { create_app_component_version("2.0.0", c_a) }
  let(:c_c1) { create_app_component('c1', 'c1') }
  let(:c_c1_100) { create_app_component_version("1.0.0", c_c1) }
  let(:c_c1_110) { create_app_component_version("1.1.0", c_c1) }
  let(:c_c1_200alpha1) { create_app_component_version("2.0.0-alpha.1", c_c1) }
  let(:c_c1_200beta1) { create_app_component_version("2.0.0-beta.1", c_c1) }
  let(:c_c2) { create_app_component('c2', 'c2') }
  let(:c_c2_100) { create_app_component_version("1.0.0", c_c2) }
  let(:c_c2_200) { create_app_component_version("2.0.0", c_c2) }
  let(:c_c3) { create_app_component('c3', 'c3') }
  let(:c_c3_100) { create_app_component_version("1.0.0", c_c3) }
  let(:c_c3_200) { create_app_component_version("2.0.0", c_c3) }

  describe ".components_dependencies" do
    before do
      App::Component.stub(:app_component) { c_a }
      c_a.stub(:cached_versions) { [c_a_200, c_a_100, c_a_200alpha1, c_a_200beta1] }
      c_a_100.stub(:dependencies) { {} }
      c_a_200.stub(:dependencies) { {} }
      c_a_200beta1.stub(:dependencies) { {} }
      c_a_200alpha1.stub(:dependencies) { {} }
      c_c1.stub(:cached_versions) { [c_c1_110, c_c1_100, c_c1_200alpha1, c_c1_200beta1] }
      c_c1_100.stub(:dependencies) { {} }
      c_c1_110.stub(:dependencies) { {} }
      c_c1_200alpha1.stub(:dependencies) { {} }
      c_c1_200beta1.stub(:dependencies) { {} }
      c_c2.stub(:cached_versions) { [c_c2_100, c_c2_200] }
      c_c2_100.stub(:dependencies) { {} }
      c_c2_200.stub(:dependencies) { {} }
      c_c3.stub(:cached_versions) { [c_c3_100, c_c3_200] }
      c_c3_100.stub(:dependencies) { {} }
      c_c3_200.stub(:dependencies) { {} }
    end

    context "with stage is stable" do
      context "with 0 site components dependencies" do
        before { site.stub(:components) { [] } }

        it "depends on the app bigger component version" do
          described_class.components_dependencies(site, 'stable').should eq('a' => "2.0.0")
        end
      end

      context "with same site components dependency with no dependencies" do
        before { site.stub(:components) { [c_a] } }

        it "depends only once on app bigger component version" do
          described_class.components_dependencies(site, 'stable').should eq('a' => "2.0.0")
        end
      end

      context "with one other site components dependency" do
        before { site.stub(:components) { [c_c1] } }

        context "with no dependencies" do
          it "depends on the both bigger components versions" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "2.0.0", 'c1' => "1.1.0")
          end
        end

        context "with app component dependency" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } }
          end

          it "depends on the both bigger components versions" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.1.0")
          end
        end

        context "with app component dependency with an unexistent dependencies" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '3.0.0' } } # unexistent
          end

          it "depends on the both bigger components versions valid" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.0.0")
          end
        end

        context "with app component dependency and another dependency" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_cached_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
          end

          it "depends on all dependencies" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '2.0.0')
          end
        end

        context "with app component dependency and another dependency with version with an impossible dependency" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_cached_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } } # impossible
          end

          it "doesn't dependence on the impossible dependency" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '1.0.0')
          end
        end

        context "with app component dependency and another dependency with another dependency" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_cached_by_name).with('c2') { c_c2 }
            App::Component.should_receive(:find_cached_by_name).with('c3') { c_c3 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '1.0.0', 'c3' => '1.0.0' } }
          end

          it "depends on all dependencies" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '2.0.0', 'c3' => '1.0.0')
          end
        end

        context "with app component dependency with a new version impossible to solve" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_cached_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c2_100.stub(:dependencies) { { 'app' => '2.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } }
          end

          it "doesn't depends on the new version" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.0.0")
          end
        end

        context "with app component dependency impossible to solve" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c2_100.stub(:dependencies) { { 'app' => '2.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } }
          end

          it "raise Solve::Errors::NoSolutionError" do
            expect { described_class.components_dependencies(site, 'stable') }.to raise_error(Solve::Errors::NoSolutionError)
          end
        end
      end
    end

    context "with stage is beta" do
      context "with one other site components dependency" do
        before { site.stub(:components) { [c_c1] } }

        context "with app component dependency and another dependency" do
          before do
            App::Component.should_receive(:find_cached_by_name).any_number_of_times.with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_200alpha1.stub(:dependencies) { { 'app' => '2.0.0-alpha.1' } }
            c_c1_200beta1.stub(:dependencies) { { 'app' => '2.0.0-beta.1' } }
          end

          it "depends on all beta dependencies" do
            described_class.components_dependencies(site, 'beta').should eq('a' => "2.0.0-beta.1", 'c1' => "2.0.0-beta.1")
          end
        end
      end
    end
  end
end
