require 'fast_spec_helper'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'
require 'rails/railtie' # for Carrierwave
require 'config/carrierwave' # for fog_mock

require 'services/loader_generator'

Site = Class.new unless defined?(Site)
App::Component = Class.new unless defined?(App::Component)
App::ComponentVersion = Class.new unless defined?(App::ComponentVersion)

unless defined?(SiteToken)
  module SiteToken
    def self.tokens
      ['ibvjcopp']
    end
  end
end

describe LoaderGenerator, :fog_mock do
  let(:site) { double("Site",
    id: 1,
    token: 'abcd1234',
    accessible_stage: 'beta',
    active?: true
  )}
  let(:component) { double(App::Component, id: 'component_id', token: 'b', app_component?: false, clear_caches: true) }
  let(:app_component) { double(App::Component, id: 'app_component_id', token: 'e', app_component?: true, clear_caches: true) }
  let(:generator) { described_class.new(site, 'stable') }
  let(:v2_4_0_alpha) { double(version: '2.4.0-alpha', solve_version: Solve::Version.new('2.4.0-alpha')) }
  let(:v2_5_0_alpha) { double(version: '2.5.0-alpha', solve_version: Solve::Version.new('2.5.0-alpha')) }
  let(:v2_5_1_alpha) { double(version: '2.5.1-alpha', solve_version: Solve::Version.new('2.5.1-alpha')) }
  let(:v2_4_0_beta) { double(version: '2.4.0-beta', solve_version: Solve::Version.new('2.4.0-beta')) }
  let(:v2_5_0_beta) { double(version: '2.5.0-beta', solve_version: Solve::Version.new('2.5.0-beta')) }
  let(:v2_5_1_beta) { double(version: '2.5.1-beta', solve_version: Solve::Version.new('2.5.1-beta')) }
  let(:v2_4_0) { double(version: '2.4.0', solve_version: Solve::Version.new('2.4.0')) }
  let(:v2_5_0) { double(version: '2.5.0', solve_version: Solve::Version.new('2.5.0')) }
  let(:v2_5_1) { double(version: '2.5.1', solve_version: Solve::Version.new('2.5.1')) }
  before do
    allow(Librato).to receive(:increment)
    allow(App::Component).to receive(:app_component) { app_component }
    allow(app_component).to receive(:versions_for_stage) { [v2_4_0, v2_5_0, v2_5_1] }
    allow(App::ComponentVersionDependenciesSolver).to receive(:components_dependencies) { {
      'e' => '1.0.0',
      'c1' => '1.2.3',
      'c2' => '1.2.4'
    } }
  end

  describe '.update_stage!' do
    before { allow(Site).to receive(:find) { site } }

    context 'site created with accessible_stage stable' do
      before { allow(site).to receive(:accessible_stage) { 'stable' } }

      it 'uploads stable loader' do
        described_class.update_stage!(site.id, 'stable')
        expect(described_class.new(site, 'stable').cdn_file).to be_present
      end

      it 'do not upload beta loader' do
        described_class.update_stage!(site.id, 'beta')
        expect(described_class.new(site, 'beta').cdn_file).not_to be_present
      end

      it 'do not upload alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
      end
    end

    context 'site created with accessible_stage beta' do
      before { allow(site).to receive(:accessible_stage) { 'beta' } }

      it 'do not upload stable loader' do
        described_class.update_stage!(site.id, 'stable')
        expect(described_class.new(site, 'stable').cdn_file).to be_present
      end

      it 'uploads beta loader' do
        described_class.update_stage!(site.id, 'beta')
        expect(described_class.new(site, 'beta').cdn_file).to be_present
      end

      it 'do not upload alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
      end
    end

    context 'site created with accessible_stage alpha' do
      before { allow(site).to receive(:accessible_stage) { 'alpha' } }

      it 'do not upload stable loader' do
        described_class.update_stage!(site.id, 'stable')
        expect(described_class.new(site, 'stable').cdn_file).to be_present
      end

      it 'uploads beta loader' do
        described_class.update_stage!(site.id, 'beta')
        expect(described_class.new(site, 'beta').cdn_file).to be_present
      end

      it 'uploads alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        expect(described_class.new(site, 'alpha').cdn_file).to be_present
      end
    end

    context 'site.accessible_stage changed from beta to stable' do
      before do
        allow(site).to receive(:accessible_stage) { 'alpha' }
        described_class.update_all_stages!(site.id)
        allow(site).to receive(:accessible_stage) { 'stable' }
      end

      context 'loaders are deletable' do
        it 'keeps the stable loader' do
          described_class.update_stage!(site.id, 'stable', deletable: true)
          expect(described_class.new(site, 'stable').cdn_file).to be_present
        end
        it 'do not keep the beta loader' do
          described_class.update_stage!(site.id, 'beta', deletable: true)
          expect(described_class.new(site, 'beta').cdn_file).not_to be_present
        end
        it 'do not keep the alpha loader' do
          described_class.update_stage!(site.id, 'alpha', deletable: true)
          expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
        end
      end

      context 'loaders are not deletable' do
        it 'keeps the stable loader' do
          described_class.update_stage!(site.id, 'stable')
          expect(described_class.new(site, 'stable').cdn_file).to be_present
        end
        it 'keeps the beta loader' do
          described_class.update_stage!(site.id, 'beta')
          expect(described_class.new(site, 'beta').cdn_file).to be_present
        end
        it 'keeps the alpha loader' do
          described_class.update_stage!(site.id, 'alpha')
          expect(described_class.new(site, 'alpha').cdn_file).to be_present
        end
      end
    end

    context 'non-active site' do
      before do
        described_class.update_all_stages!(site.id)
        expect(described_class.new(site, 'stable').cdn_file).to be_present
        expect(described_class.new(site, 'beta').cdn_file).to be_present
        expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
        allow(site).to receive(:active?) { false }
      end

      context 'loaders are deletable' do
        it 'removes the stable loader' do
          described_class.update_stage!(site.id, 'stable', deletable: true)
          expect(described_class.new(site, 'stable').cdn_file).not_to be_present
        end
        it 'removes the beta loader' do
          described_class.update_stage!(site.id, 'beta', deletable: true)
          expect(described_class.new(site, 'beta').cdn_file).not_to be_present
        end
        it 'removes the alpha loader' do
          described_class.update_stage!(site.id, 'alpha', deletable: true)
          expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
        end
      end

      context 'loaders are not deletable' do
        it 'removes the stable loader' do
          described_class.update_stage!(site.id, 'stable')
          expect(described_class.new(site, 'stable').cdn_file).to be_present
        end
        it 'removes the beta loader' do
          described_class.update_stage!(site.id, 'beta')
          expect(described_class.new(site, 'beta').cdn_file).to be_present
        end
        it 'removes the alpha loader' do
          described_class.update_stage!(site.id, 'alpha')
          expect(described_class.new(site, 'alpha').cdn_file).not_to be_present
        end
      end
    end
  end

  describe '.update_all_stages!' do
    before { allow(Site).to receive(:find) { site } }

    it 'calls .update_stage! 3 times' do
      expect(described_class).to receive(:update_stage!).with(site.id, 'stable', deletable: true)
      expect(described_class).to receive(:update_stage!).with(site.id, 'beta', deletable: true)
      expect(described_class).to receive(:update_stage!).with(site.id, 'alpha', deletable: true)

      described_class.update_all_stages!(site.id, deletable: true)
    end
  end

  describe '.update_all_dependant_sites' do
    let(:all_sites) { double }
    before do
      allow(App::Component).to receive(:find) { app_component }
      allow(described_class).to receive(:_sites_non_important) { all_sites }
      expect(all_sites).to receive(:count) { 42 }
      expect(all_sites).to receive(:find_each).and_yield(site)
    end

    it "clears caches of component" do
      expect(app_component).to receive(:clear_caches)
      described_class.update_all_dependant_sites(app_component.id, 'beta')
    end

    it 'delays notification to Campfire' do
      expect(CampfireWrapper).to delay(:post)
      described_class.update_all_dependant_sites(app_component.id, 'beta')
    end

    context "with app_component version" do
      before do
        expect(described_class).to receive(:_sites_non_important).with(component: app_component, stage: 'beta') { all_sites }
      end

      it "delays important sites update" do
        expect(described_class).to delay(:update_important_sites, queue: 'my')
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end

      it "updates all sites" do
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end

      it "delays update_all_stages! on loader queue" do
        expect(described_class).to delay(:update_all_stages!, queue: 'my-loader').with(site.id)
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end
    end

    context "with non app_component version" do
      before do
        allow(App::Component).to receive(:find) { component }
        expect(described_class).to receive(:_sites_non_important).with(component: component, stage: 'beta') { all_sites }
      end

      it "delays important sites update" do
        expect(described_class).to delay(:update_important_sites, queue: 'my')
        described_class.update_all_dependant_sites(component.id, 'beta')
      end

      it "delays update_all_stages! on loader queue" do
        expect(described_class).to delay(:update_all_stages!, queue: 'my-loader').with(site.id)
        described_class.update_all_dependant_sites(component.id, 'beta')
      end
    end
  end

  describe "Components dependencies" do
    let(:generator) { described_class.new(site, 'beta') }

    describe "#app_component_version" do
      it "returns only app component version " do
        expect(generator.app_component_version).to eq('1.0.0')
      end
    end

    describe "#components_versions" do
      it "returns all components expecting the app component" do
        expect(generator.components_versions).to eq({
          'c1' => '1.2.3',
          'c2' => '1.2.4'
        })
      end
    end
  end

  describe '#upload!' do
    context "stable loader" do
      let(:bucket) { S3Wrapper.buckets[:sublimevideo] }
      let(:path)   { "js/#{site.token}.js" }

      context "when site accessible_stage is beta" do
        describe "S3 object" do
          before { generator.upload! }

          it "is public" do
            object_acl = S3Wrapper.fog_connection.get_object_acl(bucket, path).body
            expect(object_acl['AccessControlList']).to include(
              {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
            )
          end
          it "has good content_type public" do
            object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
            expect(object_headers['Content-Type']).to eq 'text/javascript'
          end
          it "has 1 min max-age cache control" do
            object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
            expect(object_headers['Cache-Control']).to eq 's-maxage=300, max-age=120, public'
          end
        end
      end

      context "when site accessible_stage is alpha" do
        before do
          allow(site).to receive(:accessible_stage) { 'alpha' }
        end

        describe "S3 object" do
          before { generator.upload! }

          context "-alpha file" do
            let(:generator) { described_class.new(site, 'alpha') }

            it "has no-cache control" do
              object_headers = S3Wrapper.fog_connection.head_object(bucket, "js/#{site.token}-alpha.js").headers
              expect(object_headers['Cache-Control']).to eq 'no-cache'
            end
          end
        end
      end

      it 'increments delete metrics for loader' do
        expect(Librato).to receive(:increment).with('loader.update', source: 'beta')

        described_class.new(site, 'beta').upload!
      end
    end

    context "beta loader" do
      let(:generator) { described_class.new(site, 'beta') }
      let(:bucket)    { S3Wrapper.buckets[:sublimevideo] }

      describe "S3 object" do
        before do
          generator.upload!
        end
        let(:s3_object) { S3Wrapper.fog_connection.get_object(bucket, "js/#{site.token}-beta.js") }

        it "includes app version" do
          expect(s3_object.body).to include "version:\"1.0.0\""
        end

        it "includes site token" do
          expect(s3_object.body).to include "token:\"#{site.token}\""
        end

        it "includes sublinevideo host" do
          expect(s3_object.body).to include "host:\"//cdn.sublimevideo.net\""
        end

        it "includes components versions" do
          expect(s3_object.body).to include "components:{'c1':'1.2.3','c2':'1.2.4'}"
        end
      end
    end
  end

  describe '#delete!' do
    it 'increments delete metrics for loader' do
      expect(Librato).to receive(:increment).with('loader.delete', source: 'beta')

      described_class.new(site, 'beta').delete!
    end
  end

  describe '#template_file' do
    context 'alpha stage' do
    let(:generator) { described_class.new(site, 'alpha') }
      before do
        allow(app_component).to receive(:versions_for_stage) { [v2_5_0, v2_4_0, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        expect(generator.template_file).to eq 'loader-alpha.js.erb'
      end
    end

    context 'beta stage' do
      let(:generator) { described_class.new(site, 'beta') }
      before do
        allow(app_component).to receive(:versions_for_stage) { [v2_5_0, v2_4_0, v2_5_1_beta, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        expect(generator.template_file).to eq 'loader-beta.js.erb'
      end
    end

    context 'stable stage' do
      let(:generator) { described_class.new(site, 'stable') }
      before do
        allow(app_component).to receive(:versions_for_stage) { [v2_5_1, v2_5_0, v2_4_0, v2_5_1_beta, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        expect(generator.template_file).to eq 'loader-stable.js.erb'
      end
    end
  end
end

