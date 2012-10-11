require 'fast_spec_helper'
require 'rails/railtie'

require File.expand_path('app/models/app')
require File.expand_path('lib/app/component_version_dependencies_solver')

unless defined?(ActiveRecord)
  class Site < Struct.new(:player_mode); end
  class App::Component < Struct.new(:name, :token); end
  class App::ComponentVersion < Struct.new(:version, :component, :dependencies); end
end

describe App::ComponentVersionDependenciesSolver do
  let(:site) { Site.new('stable') }
  let(:c_a) { App::Component.new('app', 'a') }
  let(:c_a_100) { App::ComponentVersion.new("1.0.0", c_a) }
  let(:c_a_200) { App::ComponentVersion.new("2.0.0", c_a) }
  let(:c_c1) { App::Component.new('c1', 'c1') }
  let(:c_c1_100) { App::ComponentVersion.new("1.0.0", c_c1) }
  let(:c_c1_110) { App::ComponentVersion.new("1.1.0", c_c1) }
  let(:c_c2) { App::Component.new('c2', 'c2') }
  let(:c_c2_100) { App::ComponentVersion.new("1.0.0", c_c2) }
  let(:c_c2_200) { App::ComponentVersion.new("2.0.0", c_c2) }
  let(:c_c3) { App::Component.new('c3', 'c3') }
  let(:c_c3_100) { App::ComponentVersion.new("1.0.0", c_c3) }
  let(:c_c3_200) { App::ComponentVersion.new("2.0.0", c_c3) }

  describe ".components_dependencies" do
    before do
      App::Component.stub(:app_component) { c_a }
      c_a.stub(:versions) { [c_a_200, c_a_100] }
      c_a_100.stub(:dependencies) { {} }
      c_a_200.stub(:dependencies) { {} }
      c_c1.stub(:versions) { [c_c1_110, c_c1_100] }
      c_c1_100.stub(:dependencies) { {} }
      c_c1_110.stub(:dependencies) { {} }
      c_c2.stub(:versions) { [c_c2_100, c_c2_200] }
      c_c2_100.stub(:dependencies) { {} }
      c_c2_200.stub(:dependencies) { {} }
      c_c3.stub(:versions) { [c_c3_100, c_c3_200] }
      c_c3_100.stub(:dependencies) { {} }
      c_c3_200.stub(:dependencies) { {} }
    end

    context "player_mode is stable" do
      context "with 0 site components dependencies" do
        before { site.stub(:components) { [] } }

        it "depends on the app bigger component version" do
          described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "2.0.0")
        end
      end

      context "with same site components dependency with no dependencies" do
        before { site.stub(:components) { [c_a] } }

        it "depends only once on app bigger component version" do
          described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "2.0.0")
        end
      end

      context "with one other site components dependency" do
        before { site.stub(:components) { [c_c1] } }

        context "with no dependencies" do
          it "depends on the both bigger components versions" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "2.0.0", 'c1' => "1.1.0")
          end
        end

        context "with app component dependency" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } }
          end

          it "depends on the both bigger components versions" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.1.0")
          end
        end

        context "with app component dependency with an unexistent dependencies" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '3.0.0' } } # unexistent
          end

          it "depends on the both bigger components versions valid" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.0.0")
          end
        end

        context "with app component dependency and another dependency" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
          end

          it "depends on all dependencies" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '2.0.0')
          end
        end

        context "with app component dependency and another dependency with version with an impossible dependency" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } } # impossible
          end

          it "doesn't dependence on the impossible dependency" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '1.0.0')
          end
        end

        context "with app component dependency and another dependency with another dependency" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_by_name).with('c2') { c_c2 }
            App::Component.should_receive(:find_by_name).with('c3') { c_c3 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '>= 1.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '1.0.0', 'c3' => '1.0.0' } }
          end

          it "depends on all dependencies" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.1.0", 'c2' => '2.0.0', 'c3' => '1.0.0')
          end
        end

        context "with app component dependency with a new version impossible to solve" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_by_name).with('c2') { c_c2 }
            c_c1_100.stub(:dependencies) { { 'app' => '1.0.0' } }
            c_c1_110.stub(:dependencies) { { 'app' => '1.0.0', 'c2' => '1.0.0' } }
            c_c2_100.stub(:dependencies) { { 'app' => '2.0.0' } }
            c_c2_200.stub(:dependencies) { { 'app' => '2.0.0' } }
          end

          it "doesn't depends on the new version" do
            described_class.components_dependencies(site, 'stable').dependencies.should eq('a' => "1.0.0", 'c1' => "1.0.0")
          end
        end

        context "with app component dependency impossible to solve" do
          before do
            App::Component.should_receive(:find_by_name).any_number_of_times.with('app') { c_a }
            App::Component.should_receive(:find_by_name).any_number_of_times.with('c2') { c_c2 }
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
  end

end
