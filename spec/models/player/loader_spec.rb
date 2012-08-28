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

describe Player::Loader, :fog_mock do
  let(:loader) { Player::Loader.new('alpha', '2.0.0') }
  let(:bucket) { S3.buckets['sublimevideo'] }

  describe "filename" do
    it "is loader.js with stable tag" do
      loader.tag = 'stable'
      loader.filename.should eq 'loader.js'
    end

    it "is loader-tag.js with other tag" do
      loader.tag = 'alpha'
      loader.filename.should eq 'loader-alpha.js'
    end
  end

  describe "initialize" do
    it "generates properly the loader file from templates" do
      loader.file.should be_present
    end
  end

  describe "upload!" do
    before { CDN.stub(:purge) }

    describe "uploaded loader file" do
      before { loader.upload! }

      it "is public" do
        object_acl = S3.fog_connection.get_object_acl(bucket, loader.filename).body
        object_acl['AccessControlList'].should include(
          {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
        )
      end
      it "have good content_type public" do
        object_headers = S3.fog_connection.get_object(bucket, loader.filename).headers
        object_headers['Content-Type'].should eq 'text/javascript'
      end
      it "have long max-age cache control" do
        object_headers = S3.fog_connection.get_object(bucket, loader.filename).headers
        object_headers['Cache-Control'].should eq 'max-age=300, public'
      end
      it "includes good loader version" do
        object = S3.fog_connection.get_object(bucket, loader.filename)
        object.body.should include '2.0.0'
      end
    end

    it "purges loader file from CDN" do
      CDN.should_receive(:purge).with(loader.filename)
      loader.upload!
    end
  end

end
