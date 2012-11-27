require 'spec_helper'

describe Service::App::ComponentVersion do
  let(:bucket) { S3.buckets['sublimevideo'] }
  let(:site) {
    site = build(:site)
    Service::Site.new(site).create
    site
  }
  let(:component) { site.components.first }
  let(:component_version) { component.versions.build({ token: component.token, version: '2.0.0', zip: zip }, as: :admin) }
  let(:zip) { fixture_file('app/e.zip') }

  before {
    CDN.stub(:purge)
    component.versions.create({ token: component.token, version: '1.0.0', zip: zip }, as: :admin)
  }

  describe "#create" do

    it "updates site loader" do
      component.versions.last.version.should_not eq component_version.version

      Sidekiq::Worker.clear_all
      Service::App::ComponentVersion.new(component_version).create
      Sidekiq::Worker.drain_all

      S3.fog_connection.get_object(bucket, "js/#{site.token}-beta.js").body.should include component_version.version
    end
  end

  describe "#delete" do
    before do
      Sidekiq::Worker.clear_all
      Service::App::ComponentVersion.new(component_version).create
      Sidekiq::Worker.drain_all
    end

    it "keeps old component version on S3 but updates site loader" do
      Service::App::ComponentVersion.new(component_version).destroy
      Sidekiq::Worker.drain_all

      S3.fog_connection.head_object(bucket, "c/#{component.token}/#{component_version.version}/bA.js").headers.should be_present
      S3.fog_connection.get_object(bucket, "js/#{site.token}-beta.js").body.should include '1.0.0'
    end
  end

end
