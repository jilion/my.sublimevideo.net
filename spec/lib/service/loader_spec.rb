require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')
require File.expand_path('lib/s3')
require File.expand_path('lib/stage')
require File.expand_path('app/models/app')
require File.expand_path('lib/app/mangler')

unless defined?(ActiveRecord)
  Site = Class.new
  App::Component = Class.new
  App::ComponentVersion = Class.new
end

require File.expand_path('lib/service/loader')

describe Service::Loader, :fog_mock do
  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    accessible_stage: 'beta', player_mode: 'beta',
    active?: true
  )}
  let(:component) { mock(App::Component, token: 'b', app_component?: false) }
  let(:app_component) { mock(App::Component, token: 'e', app_component?: true) }
  let(:loader) { described_class.new(site, 'stable') }
  before do
    App::Component.stub(:app_component) { app_component }
    App::ComponentVersionDependenciesSolver.stub(:components_dependencies) { {
      'e' => '1.0.0',
      'c1' => '1.2.3',
      'c2' => '1.2.4',
    } }
  end

  describe ".update_all_stages!" do
    before { Site.stub(:find) { site } }

    context "site created with accessible_stage stable" do
      before { site.stub(:accessible_stage) { 'stable' } }

      it "uploads only stable loader" do
        described_class.update_all_stages!(site.id)
        described_class.new(site, 'stable').should be_present
        described_class.new(site, 'beta').should_not be_present
        described_class.new(site, 'alpha').should_not be_present
      end
    end

    context "site created with accessible_stage beta" do
      before do
        site.stub(:accessible_stage) { 'beta' }
        described_class.update_all_stages!(site.id)
      end

      it "uploads stable & beta loaders" do
        described_class.new(site, 'stable').should be_present
        described_class.new(site, 'beta').should be_present
        described_class.new(site, 'alpha').should_not be_present
      end
    end

    context "site created with accessible_stage alpha" do
      before do
        site.stub(:accessible_stage) { 'alpha' }
        described_class.update_all_stages!(site.id)
      end

      it "uploads all loaders" do
        described_class.new(site, 'stable').should be_present
        described_class.new(site, 'beta').should be_present
        described_class.new(site, 'alpha').should be_present
      end
    end

    context "site.accessible_stage changed from 'beta' to 'stable'" do
      before do
        site.stub(:accessible_stage) { 'beta' }
        described_class.update_all_stages!(site.id)
        site.stub(:accessible_stage) { 'stable' }
      end

      it "keeps only stable loader" do
        described_class.update_all_stages!(site.id)
        described_class.new(site, 'stable').should be_present
        described_class.new(site, 'beta').should_not be_present
        described_class.new(site, 'alpha').should_not be_present
      end
    end

    context "site.accessible_stage not changed" do
      before do
        site.stub(:accessible_stage) { 'alpha' }
        described_class.update_all_stages!(site.id)
      end

      it "keeps all loaders" do
        described_class.update_all_stages!(site.id)
        described_class.new(site, 'stable').should be_present
        described_class.new(site, 'beta').should be_present
        described_class.new(site, 'alpha').should be_present
      end
    end

    context "non-active site" do
      before do
        site.stub(:active?) { false }
        described_class.update_all_stages!(site.id)
      end

      it "removes all loaders" do
        described_class.new(site, 'stable').should_not be_present
        described_class.new(site, 'beta').should_not be_present
        described_class.new(site, 'alpha').should_not be_present
      end
    end
  end

  describe ".update_all_dependant_sites" do
    let(:scoped_sites) { mock(Site) }
    before do
      App::ComponentVersion.stub(:find) { component_version }
      scoped_sites.stub_chain(:active, :where) { scoped_sites }
      site.stub(:last_30_days_billable_video_views) { 0 }
      scoped_sites.stub(:find_each).and_yield(site)
    end

    context "with app_component version" do
      let(:component_version) { mock(App::ComponentVersion,
        id: 'component_version_id',
        component: app_component,
        stage: 'stable'
      )}
      before { Site.stub(:scoped) { scoped_sites } }

      it "updates all sites" do
        Site.should_receive(:scoped) { scoped_sites }
        described_class.update_all_dependant_sites(component_version.id)
      end

      it "delays update_all_stages! with high queue" do
        site.should_receive(:last_30_days_billable_video_views) { 1 }
        described_class.should delay(:update_all_stages!, queue: 'high').with(site.id)
        described_class.update_all_dependant_sites(component_version.id)
      end
    end

    context "with non app_component version" do
      let(:component_version) { mock(App::ComponentVersion,
        id: 'component_version_id',
        component: component,
        stage: 'stable'
      )}
      before { component.stub_chain(:sites, :scoped) { scoped_sites } }

      it "updates component_version component's sites" do
        component.should_receive(:sites) { scoped_sites }
        scoped_sites.should_receive(:scoped) { scoped_sites }
        described_class.update_all_dependant_sites(component_version.id)
      end

      it "delays update_all_stages! with low queue" do
        described_class.should delay(:update_all_stages!, queue: 'low').with(site.id)
        described_class.update_all_dependant_sites(component_version.id)
      end
    end
  end

  describe "Components dependencies" do
    let(:loader) { described_class.new(site, 'beta') }

    describe "#app_component_version" do
      it "returns only app component version " do
        loader.app_component_version.should eq('1.0.0')
      end
    end

    describe "#components_versions" do
      it "returns all components expecting the app component" do
        loader.components_versions.should eq({
          'c1' => '1.2.3',
          'c2' => '1.2.4'
        })
      end
    end
  end

  describe "#upload!" do
    context "stable loader" do
      let(:bucket) { S3.buckets['sublimevideo'] }
      let(:path)   { "js/#{site.token}.js" }

      context "when site accessible_stage is beta" do
        describe "S3 object" do
          before { loader.upload! }

          it "is public" do
            object_acl = S3.fog_connection.get_object_acl(bucket, path).body
            object_acl['AccessControlList'].should include(
              {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
            )
          end
          it "have good content_type public" do
            object_headers = S3.fog_connection.head_object(bucket, path).headers
            object_headers['Content-Type'].should eq 'text/javascript'
          end
          it "have 1 min max-age cache control" do
            object_headers = S3.fog_connection.head_object(bucket, path).headers
            object_headers['Cache-Control'].should eq 'max-age=60, public'
          end
          it "includes good loader version" do
            object = S3.fog_connection.get_object(bucket, path)
            object.body.should include '/p/beta/sublime.js'
          end
        end
      end

      context "when site accessible_stage is alpha" do
        before do
          site.stub(:accessible_stage) { 'alpha' }
          site.stub(:player_mode) { 'dev' }
        end

        describe "S3 object" do
          before { loader.upload! }

          it "includes good loader version" do
            object = S3.fog_connection.get_object(bucket, path)
            object.body.should include '/p/dev/sublime.js'
          end
        end
      end
    end

    context "beta loader" do
      let(:loader) { described_class.new(site, 'beta') }
      let(:bucket) { S3.buckets['sublimevideo'] }
      let(:path)   { "js/#{site.token}-beta.js" }

      describe "S3 object" do
        before do
          loader.upload!
        end
        let(:s3_object) { S3.fog_connection.get_object(bucket, path) }

        it "includes app version" do
          s3_object.body.should include "version:'1.0.0'"
        end

        it "includes site token" do
          s3_object.body.should include "#{App::Mangler.mangle_key(:token)}:'#{site.token}'"
        end

        it "includes sublinevideo host" do
          s3_object.body.should include "#{App::Mangler.mangle_key(:host)}:'//cdn.sublimevideo.net'"
        end

        it "includes components versions" do
          s3_object.body.should include "#{App::Mangler.mangle_key(:components)}:{'c1':'1.2.3','c2':'1.2.4'}"
        end
      end
    end
  end
end

