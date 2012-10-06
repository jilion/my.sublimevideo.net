require 'fast_spec_helper'
require 'rails/railtie'

require File.expand_path('lib/semantic_versioning')
require File.expand_path('app/models/app')
require File.expand_path('lib/app/component_version_dependencies_manager')

unless defined?(ActiveRecord)
  class Site < Struct.new(:player_mode); end
  class App::Component < Struct.new(:name, :token); end
  class App::ComponentVersion < Struct.new(:version, :component, :dependencies)
    include SemanticVersioning
  end
end

describe App::ComponentVersionDependenciesManager do
  let(:site) { Site.new('stable') }
  let(:c_a) { App::Component.new('app', 'a') }
  let(:c_a_100) { App::ComponentVersion.new("1.0.0", c_a) }
  let(:c_a_200) { App::ComponentVersion.new("2.0.0", c_a) }
  let(:c_c1) { App::Component.new('c1', 'c1') }
  let(:c_c1_100) { App::ComponentVersion.new("1.0.0", c_a) }
  let(:c_c1_110) { App::ComponentVersion.new("1.1.0", c_a) }

  pending ".components_dependencies" do
    before do
      App::Component.stub(:app_component) { c_a }
      c_a.stub(:versions) { [c_a_200, c_a_100] }
      c_c1.stub(:versions) { [c_c1_110, c_a_100] }
    end

    context "player_mode is stable" do
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
           before { c_c1_110.stub(:dependencies) { { 'app' => '1.0.0' } } }

          it "depends on the both bigger components versions" do
            described_class.components_dependencies(site, 'stable').should eq('a' => "1.0.0", 'c1' => "1.1.0")
          end
        end
      end
    end
  end

end
