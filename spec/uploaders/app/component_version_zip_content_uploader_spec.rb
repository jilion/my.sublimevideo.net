require 'fast_spec_helper'
require 'configurator'
require 'zip/zip'
require 'rails/railtie'
require 'fog'
require 'config/carrierwave' # for fog_mock
require 'support/fixtures_helpers'

require 'models/app'
require 'uploaders/app/component_version_zip_content_uploader'
require 'wrappers/s3_wrapper'
require 'services/file_header_analyzer'

describe App::ComponentVersionZipContentUploader, :fog_mock do

  let(:zip) { fixture_file('app/e.zip') }
  ### Zip content
  # bA.js
  # flash/flash11canvas.swf
  # flash/sublimevideo.swf
  # images/logo.png
  # images/play_button.png
  # images/sub/sub_play_button.png
  let(:upload_path) { Pathname.new('b/e/2.0.0/') }
  let(:bucket) { S3Wrapper.buckets['sublimevideo'] }
  let(:js_object_path) { upload_path.join('bA.js').to_s }
  let(:uploader) { described_class.new(upload_path) }

  describe ".store_zip_content" do
    it "sends all zip files in sublimvideo S3 bucket" do
      uploader.should_receive(:put_object).exactly(6).times
      uploader.store_zip_content(zip.path)
    end

    context "file uploaded" do
      before { uploader.store_zip_content(zip.path) }

      it "is public" do
        object_acl = S3Wrapper.fog_connection.get_object_acl(bucket, js_object_path).body
        object_acl['AccessControlList'].should include(
          {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
        )
      end
      it "have good content_type public" do
        object_headers = S3Wrapper.fog_connection.get_object(bucket, js_object_path).headers
        object_headers['Content-Type'].should eq 'text/javascript'
      end
      it "have long max-age cache control" do
        object_headers = S3Wrapper.fog_connection.get_object(bucket, js_object_path).headers
        object_headers['Cache-Control'].should eq 'max-age=29030400, public'
      end
    end
  end

  describe ".remove_zip_content" do
    before { uploader.store_zip_content(zip.path) }

    it "removes all files in sublimevideo S3 bucket" do
      uploader.remove_zip_content
      S3Wrapper.fog_connection.directories.get(
        S3Wrapper.buckets['sublimevideo'],
        prefix: upload_path.to_s
      ).files.should have(0).files
    end
  end

end
