require 'fast_spec_helper'
require 'config/sidekiq'
require 'timecop'
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
    Librato.stub(:increment)
    App::Component.stub(:app_component) { app_component }
    app_component.stub(:versions_for_stage) { [v2_4_0, v2_5_0, v2_5_1] }
    App::ComponentVersionDependenciesSolver.stub(:components_dependencies) { {
      'e' => '1.0.0',
      'c1' => '1.2.3',
      'c2' => '1.2.4'
    } }
  end

  describe '.update_stage!' do
    before { Site.stub(:find) { site } }

    context 'site created with accessible_stage stable' do
      before { site.stub(:accessible_stage) { 'stable' } }

      it 'uploads stable loader' do
        described_class.update_stage!(site.id, 'stable')
        described_class.new(site, 'stable').cdn_file.should be_present
      end

      it 'do not upload beta loader' do
        described_class.update_stage!(site.id, 'beta')
        described_class.new(site, 'beta').cdn_file.should_not be_present
      end

      it 'do not upload alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        described_class.new(site, 'alpha').cdn_file.should_not be_present
      end
    end

    context 'site created with accessible_stage beta' do
      before { site.stub(:accessible_stage) { 'beta' } }

      it 'do not upload stable loader' do
        described_class.update_stage!(site.id, 'stable')
        described_class.new(site, 'stable').cdn_file.should be_present
      end

      it 'uploads beta loader' do
        described_class.update_stage!(site.id, 'beta')
        described_class.new(site, 'beta').cdn_file.should be_present
      end

      it 'do not upload alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        described_class.new(site, 'alpha').cdn_file.should_not be_present
      end
    end

    context 'site created with accessible_stage alpha' do
      before { site.stub(:accessible_stage) { 'alpha' } }

      it 'do not upload stable loader' do
        described_class.update_stage!(site.id, 'stable')
        described_class.new(site, 'stable').cdn_file.should be_present
      end

      it 'uploads beta loader' do
        described_class.update_stage!(site.id, 'beta')
        described_class.new(site, 'beta').cdn_file.should be_present
      end

      it 'uploads alpha loader' do
        described_class.update_stage!(site.id, 'alpha')
        described_class.new(site, 'alpha').cdn_file.should be_present
      end
    end

    context 'site.accessible_stage changed from beta to stable' do
      before do
        site.stub(:accessible_stage) { 'alpha' }
        described_class.update_all_stages!(site.id)
        site.stub(:accessible_stage) { 'stable' }
      end

      context 'loaders are deletable' do
        it 'keeps the stable loader' do
          described_class.update_stage!(site.id, 'stable', deletable: true)
          described_class.new(site, 'stable').cdn_file.should be_present
        end
        it 'do not keep the beta loader' do
          described_class.update_stage!(site.id, 'beta', deletable: true)
          described_class.new(site, 'beta').cdn_file.should_not be_present
        end
        it 'do not keep the alpha loader' do
          described_class.update_stage!(site.id, 'alpha', deletable: true)
          described_class.new(site, 'alpha').cdn_file.should_not be_present
        end
      end

      context 'loaders are not deletable' do
        it 'keeps the stable loader' do
          described_class.update_stage!(site.id, 'stable')
          described_class.new(site, 'stable').cdn_file.should be_present
        end
        it 'keeps the beta loader' do
          described_class.update_stage!(site.id, 'beta')
          described_class.new(site, 'beta').cdn_file.should be_present
        end
        it 'keeps the alpha loader' do
          described_class.update_stage!(site.id, 'alpha')
          described_class.new(site, 'alpha').cdn_file.should be_present
        end
      end
    end

    context 'non-active site' do
      before do
        described_class.update_all_stages!(site.id)
        described_class.new(site, 'stable').cdn_file.should be_present
        described_class.new(site, 'beta').cdn_file.should be_present
        described_class.new(site, 'alpha').cdn_file.should_not be_present
        site.stub(:active?) { false }
      end

      context 'loaders are deletable' do
        it 'removes the stable loader' do
          described_class.update_stage!(site.id, 'stable', deletable: true)
          described_class.new(site, 'stable').cdn_file.should_not be_present
        end
        it 'removes the beta loader' do
          described_class.update_stage!(site.id, 'beta', deletable: true)
          described_class.new(site, 'beta').cdn_file.should_not be_present
        end
        it 'removes the alpha loader' do
          described_class.update_stage!(site.id, 'alpha', deletable: true)
          described_class.new(site, 'alpha').cdn_file.should_not be_present
        end
      end

      context 'loaders are not deletable' do
        it 'removes the stable loader' do
          described_class.update_stage!(site.id, 'stable')
          described_class.new(site, 'stable').cdn_file.should be_present
        end
        it 'removes the beta loader' do
          described_class.update_stage!(site.id, 'beta')
          described_class.new(site, 'beta').cdn_file.should be_present
        end
        it 'removes the alpha loader' do
          described_class.update_stage!(site.id, 'alpha')
          described_class.new(site, 'alpha').cdn_file.should_not be_present
        end
      end
    end
  end

  describe '.update_all_stages!' do
    before { Site.stub(:find) { site } }

    it 'calls .update_stage! 3 times' do
      described_class.should_receive(:update_stage!).with(site.id, 'stable', deletable: true)
      described_class.should_receive(:update_stage!).with(site.id, 'beta', deletable: true)
      described_class.should_receive(:update_stage!).with(site.id, 'alpha', deletable: true)

      described_class.update_all_stages!(site.id, deletable: true)
    end
  end

  describe '.update_all_dependant_sites' do
    let(:all_sites) { double }
    before do
      App::Component.stub(:find) { app_component }
      described_class.stub(:_sites_non_important) { all_sites }
      all_sites.should_receive(:count) { 42 }
      all_sites.should_receive(:find_each).and_yield(site)
    end

    it "clears caches of component" do
      app_component.should_receive(:clear_caches)
      described_class.update_all_dependant_sites(app_component.id, 'beta')
    end

    it 'delays notification to Campfire' do
      CampfireWrapper.should delay(:post)
      described_class.update_all_dependant_sites(app_component.id, 'beta')
    end

    context "with app_component version" do
      before do
        described_class.should_receive(:_sites_non_important).with(component: app_component, stage: 'beta') { all_sites }
      end

      it "delays important sites update" do
        described_class.should delay(:update_important_sites, queue: 'my')
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end

      it "updates all sites" do
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end

      it "delays update_all_stages! on loader queue" do
        described_class.should delay(:update_all_stages!, queue: 'my-loader').with(site.id)
        described_class.update_all_dependant_sites(app_component.id, 'beta')
      end
    end

    context "with non app_component version" do
      before do
        App::Component.stub(:find) { component }
        described_class.should_receive(:_sites_non_important).with(component: component, stage: 'beta') { all_sites }
      end

      it "delays important sites update" do
        described_class.should delay(:update_important_sites, queue: 'my')
        described_class.update_all_dependant_sites(component.id, 'beta')
      end

      it "delays update_all_stages! on loader queue" do
        described_class.should delay(:update_all_stages!, queue: 'my-loader').with(site.id)
        described_class.update_all_dependant_sites(component.id, 'beta')
      end
    end
  end

  describe "Components dependencies" do
    let(:generator) { described_class.new(site, 'beta') }

    describe "#app_component_version" do
      it "returns only app component version " do
        generator.app_component_version.should eq('1.0.0')
      end
    end

    describe "#components_versions" do
      it "returns all components expecting the app component" do
        generator.components_versions.should eq({
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
            object_acl['AccessControlList'].should include(
              {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
            )
          end
          it "has good content_type public" do
            object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
            object_headers['Content-Type'].should eq 'text/javascript'
          end
          it "has 1 min max-age cache control" do
            object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
            object_headers['Cache-Control'].should eq 's-maxage=300, max-age=120, public'
          end
          it "has Last-Modified" do
            Timecop.freeze do
              object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
              time = object_headers['Last-Modified']
              expect(Time.parse(time)).to eq Time.now.to_s
            end
          end
        end
      end

      context "when site accessible_stage is alpha" do
        before do
          site.stub(:accessible_stage) { 'alpha' }
        end

        describe "S3 object" do
          before { generator.upload! }

          context "-alpha file" do
            let(:generator) { described_class.new(site, 'alpha') }

            it "has no-cache control" do
              object_headers = S3Wrapper.fog_connection.head_object(bucket, "js/#{site.token}-alpha.js").headers
              object_headers['Cache-Control'].should eq 'no-cache'
            end
          end
        end
      end

      it 'increments delete metrics for loader' do
        Librato.should_receive(:increment).with('loader.update', source: 'beta')

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
          s3_object.body.should include "version:\"1.0.0\""
        end

        it "includes site token" do
          s3_object.body.should include "token:\"#{site.token}\""
        end

        it "includes sublinevideo host" do
          s3_object.body.should include "host:\"//cdn.sublimevideo.net\""
        end

        it "includes components versions" do
          s3_object.body.should include "components:{'c1':'1.2.3','c2':'1.2.4'}"
        end
      end
    end
  end

  describe '#delete!' do
    it 'increments delete metrics for loader' do
      Librato.should_receive(:increment).with('loader.delete', source: 'beta')

      described_class.new(site, 'beta').delete!
    end
  end

  describe '#template_file' do
    context 'alpha stage' do
    let(:generator) { described_class.new(site, 'alpha') }
      before do
        app_component.stub(:versions_for_stage) { [v2_5_0, v2_4_0, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        generator.template_file.should eq 'loader-alpha.js.erb'
      end
    end

    context 'beta stage' do
      let(:generator) { described_class.new(site, 'beta') }
      before do
        app_component.stub(:versions_for_stage) { [v2_5_0, v2_4_0, v2_5_1_beta, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        generator.template_file.should eq 'loader-beta.js.erb'
      end
    end

    context 'stable stage' do
      let(:generator) { described_class.new(site, 'stable') }
      before do
        app_component.stub(:versions_for_stage) { [v2_5_1, v2_5_0, v2_4_0, v2_5_1_beta, v2_5_0_beta, v2_4_0_beta, v2_5_1_alpha, v2_5_0_alpha, v2_4_0_alpha] }
      end

      it 'returns the new loader' do
        generator.template_file.should eq 'loader-stable.js.erb'
      end
    end
  end
end

