require 'fast_spec_helper'
require 'zip/zip'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('spec/support/fixtures_helpers')

require File.expand_path('app/models/player')
require File.expand_path('app/uploaders/player/bundle_version_zip_content_uploader')

describe Player::BundleVersionZipContentUploader, :fog_mock do

  let(:zip) { fixture_file('player/bA.zip') }
  ### Zip content
  # bA.js
  # flash/flash11canvas.swf
  # flash/sublimevideo.swf
  # images/logo.png
  # images/play_button.png
  # images/sub/sub_play_button.png
  let(:upload_path) { Pathname.new('b/bA/2.0.0') }
  let(:bucket) { S3.buckets['sublimevideo'] }
  it "sends all zip files in sublimvideo S3 buckets" do
    described_class.should_receive(:put_object).exactly(6).times
    described_class.upload_zip_content(zip.path, upload_path)
  end

  context "when files uploaded" do
    let(:js_object_path) { upload_path.join('bA.js').to_s }
    before { described_class.upload_zip_content(zip.path, upload_path) }

    it "sets file public" do
      object_acl = described_class.fog_connection.get_object_acl(bucket, js_object_path).body
      object_acl['AccessControlList'].should include(
        {"Permission"=>"READ", "Grantee"=>{"URI"=>"http://acs.amazonaws.com/groups/global/AllUsers"}}
      )
    end
    it "sets good content_type public" do
      object_headers = described_class.fog_connection.get_object(bucket, js_object_path).headers
      object_headers['Content-Type'].should eq 'text/javascript'
    end
    it "sets long max-age cache control" do
      object_headers = described_class.fog_connection.get_object(bucket, js_object_path).headers
      object_headers['Cache-Control'].should eq 'max-age=29030400, public'
    end
  end

end
