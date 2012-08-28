require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('lib/s3')
require File.expand_path('app/models/player')
require File.expand_path('app/models/player/settings')

describe Player::Settings, :fog_mock do
  let(:site) { mock("Site",
    token: 'abcd1234',
    hostname: 'test.com',
    extra_hostnames: 'test.net', extra_hostnames?: true,
    dev_hostnames: 'test.dev', dev_hostnames?: true,
    wildcard: true, wildcard?: true,
    path: '/path', path?: true,
    badged: false,
    in_free_plan?: true,
    plan_stats_retention_days: 365,
    touch: true
  )}
  let(:settings) { Player::Settings.new(site) }
  let(:bucket) { S3.buckets['sublimevideo'] }

  describe "#filepath" do
    it "includes the site token" do
      settings.filepath.should eq 's/abcd1234.js'
    end
  end

  describe "initialize" do
    it "generates properly the loader file from templates" do
      settings.file.should be_present
    end
  end

  describe "#hash" do
    it "includes all site settings" do
      settings.hash.should eq({
       h: ["test.com", "test.net"],
       d: ["test.dev"],
       w: true,
       p: "/path",
       b: false,
       r: true
      })
    end
  end

  describe "#json" do
    it "transtorms hash to json" do
      settings.json.should eq(
        "{h:[\"test.com\",\"test.net\"],d:[\"test.dev\"],w:true,p:\"/path\",b:false,r:true}"
      )
    end
  end

  describe "#upload!" do
    before { CDN.stub(:purge) }

    describe "uploaded loader file" do
      before { settings.upload! }

      it "is public" do
        object_acl = S3.fog_connection.get_object_acl(bucket, settings.filepath).body
        object_acl['AccessControlList'].should include(
          {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
        )
      end
      it "have good content_type public" do
        object_headers = S3.fog_connection.get_object(bucket, settings.filepath).headers
        object_headers['Content-Type'].should eq 'text/javascript'
      end
      it "have 2 min max-age cache control" do
        object_headers = S3.fog_connection.get_object(bucket, settings.filepath).headers
        object_headers['Cache-Control'].should eq 'max-age=120, public'
      end
      it "includes settings json version" do
        object = S3.fog_connection.get_object(bucket, settings.filepath)
        object.body.should include settings.json
      end
    end

    it "purges loader file from CDN" do
      CDN.should_receive(:purge).with(settings.filepath)
      settings.upload!
    end

    it "touch site settings_updated_at" do
      settings.site.should_receive(:touch).with(:settings_updated_at)
      settings.upload!
    end
  end

  describe "#delete!" do
    before do
      CDN.stub(:purge)
      settings.upload!
    end

    it "deletes settings file" do
      settings.delete!
      expect { S3.fog_connection.get_object(bucket, settings.filepath) }.to raise_error(Excon::Errors::NotFound)
    end

    it "purges loader file from CDN" do
      CDN.should_receive(:purge).with(settings.filepath)
      settings.delete!
    end

    it "touch site settings_updated_at" do
      settings.site.should_receive(:touch).with(:settings_updated_at)
      settings.upload!
    end
  end

end
