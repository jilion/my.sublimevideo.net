require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('lib/s3')
require File.expand_path('app/models/player')
require File.expand_path('app/models/player/loader')

Site = Class.new unless defined?(Site)

describe Player::Loader, :fog_mock do
  before { CDN.stub(:purge) }
  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    player_mode: 'beta',
    state: 'active',
    touch: true
  )}
  let(:loader) { Player::Loader.new(site, 'stable') }

  describe ".update_all_modes!" do
    before { Site.stub(:find) { site } }

    context "site created with player_mode stable" do
      before { site.stub(:player_mode) { 'stable' } }

      it "uploads only stable loader" do
        Player::Loader.update_all_modes!(site.id)
        Player::Loader.new(site, 'stable').should be_present
        Player::Loader.new(site, 'beta').should_not be_present
        Player::Loader.new(site, 'alpha').should_not be_present
      end

      it "touch loaders_updated_at" do
        site.should_receive(:touch).with(:loaders_updated_at)
        Player::Loader.update_all_modes!(site.id)
      end
    end

    context "site created with player_mode beta" do
      before do
        site.stub(:player_mode) { 'beta' }
        Player::Loader.update_all_modes!(site.id)
      end

      it "uploads stable & beta loaders" do
        Player::Loader.new(site, 'stable').should be_present
        Player::Loader.new(site, 'beta').should be_present
        Player::Loader.new(site, 'alpha').should_not be_present
      end
    end

    context "site created with player_mode alpha" do
      before do
        site.stub(:player_mode) { 'alpha' }
        Player::Loader.update_all_modes!(site.id)
      end

      it "uploads all loaders" do
        Player::Loader.new(site, 'stable').should be_present
        Player::Loader.new(site, 'beta').should be_present
        Player::Loader.new(site, 'alpha').should be_present
      end
    end

    context "site.player_mode changed from 'beta' to 'stable'" do
      before do
        site.stub(:player_mode) { 'beta' }
        Player::Loader.update_all_modes!(site.id)
        site.stub(:player_mode) { 'stable' }
      end

      it "keeps only stable loader" do
        Player::Loader.update_all_modes!(site.id)
        Player::Loader.new(site, 'stable').should be_present
        Player::Loader.new(site, 'beta').should_not be_present
        Player::Loader.new(site, 'alpha').should_not be_present
      end

      it "touch loaders_updated_at" do
        site.should_receive(:touch).with(:loaders_updated_at)
        Player::Loader.update_all_modes!(site.id)
      end
    end

    context "site.player_mode not changed" do
      before do
        site.stub(:player_mode) { 'alpha' }
        Player::Loader.update_all_modes!(site.id)
      end

      it "keeps all loaders" do
        Player::Loader.update_all_modes!(site.id)
        Player::Loader.new(site, 'stable').should be_present
        Player::Loader.new(site, 'beta').should be_present
        Player::Loader.new(site, 'alpha').should be_present
      end

      it "doesn't touch loaders_updated_at" do
        site.should_not_receive(:touch).with(:loaders_updated_at)
        Player::Loader.update_all_modes!(site.id)
      end
    end

    context "site with suspended state" do
      before do
        site.stub(:state) { 'suspended' }
        Player::Loader.update_all_modes!(site.id)
      end

      it "removes all loaders" do
        Player::Loader.new(site, 'stable').should_not be_present
        Player::Loader.new(site, 'beta').should_not be_present
        Player::Loader.new(site, 'alpha').should_not be_present
      end
    end

    context "site with archived state" do
      before do
        site.stub(:state) { 'archived' }
        Player::Loader.update_all_modes!(site.id)
      end

      it "removes all loaders" do
        Player::Loader.new(site, 'stable').should_not be_present
        Player::Loader.new(site, 'beta').should_not be_present
        Player::Loader.new(site, 'alpha').should_not be_present
      end
    end

  end

  describe "#upload!" do

    describe "S3 object" do
      before { loader.upload! }
      let(:bucket) { S3.buckets['sublimevideo'] }
      let(:path)   { "js/#{site.token}.js" }

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
      it "have 5 min max-age cache control" do
        object_headers = S3.fog_connection.head_object(bucket, path).headers
        object_headers['Cache-Control'].should eq 'max-age=120, public'
      end
      it "includes good loader version" do
        object = S3.fog_connection.get_object(bucket, path)
        object.body.should include '/p/beta/sublime.js'
      end
    end

  end
end

