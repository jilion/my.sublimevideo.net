require 'fast_spec_helper'
require 'support/fixtures_helpers'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('lib/cdn/file')

describe CDN::File, :fog_mock do
  before { CDN.stub(:purge) }

  let(:file) { fixture_file('cdn/file.js', 'r') }
  let(:file2) { fixture_file('cdn/file2.js', 'r') }
  let(:destinations) { [{
    bucket: S3.buckets['sublimevideo'],
    path: "js/token.js"
  },{
    bucket: S3.buckets['loaders'],
    path: "loaders/token.js"
  }] }
  let(:s3_options) { {
    'Cache-Control' => 'max-age=120, public', # 2 minutes
    'Content-Type'  => 'text/javascript',
    'x-amz-acl'     => 'public-read'
  } }
  let(:cdn_file) { CDN::File.new(file, destinations, s3_options) }

  describe "#upload!" do
    it "uploads file to all destinations" do
      cdn_file.upload!
      destinations.each do |destination|
        S3.fog_connection.head_object(
          destination[:bucket],
          destination[:path]
        ).headers.should be_present
      end
    end

    describe "s3 object(s)" do
      before { cdn_file.upload! }

      let(:bucket) { destinations.first[:bucket] }
      let(:path)   { destinations.first[:path] }

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
      it "have Content-MD5" do
        object_headers = S3.fog_connection.head_object(bucket, path).headers
        File.open(file) do |f|
          object_headers['Content-MD5'].should eq Digest::MD5.base64digest(f.read)
        end
      end
    end

    describe "cdn purge" do
      it "is called with new file" do
        CDN.should_receive(:purge).with("/js/token.js")
        cdn_file.upload!
      end

      it "is not called with new file when purge option is false" do
        cdn_file = CDN::File.new(file, destinations, s3_options, purge: false)
        CDN.should_not_receive(:purge).with("/js/token.js")
        cdn_file.upload!
      end

      it "is called with modified file" do
        cdn_file.upload!
        CDN.should_receive(:purge).with("/js/token.js")
        cdn_file.file = file2
        cdn_file.upload!
      end

      it "isn't called when same file was already uploaded" do
        cdn_file.upload!
        CDN.should_not_receive(:purge).with("/js/token.js")
        cdn_file.upload!
      end
    end

    describe "respond" do
      it "is true when file wasn't present before" do
        cdn_file.upload!.should be_true
      end

      it "is true when an other file is present" do
        cdn_file.upload!
        cdn_file.file = file2
        cdn_file.upload!.should be_true
      end

      it "is false when the same file is already present" do
        cdn_file.upload!
        cdn_file.upload!.should be_false
      end
    end
  end

  describe "#delete!" do
    context "with file present" do
      before { cdn_file.upload! }

      it "remove S3 object" do
        cdn_file.delete!
        cdn_file.should_not be_present
      end

      it "returns true" do
        cdn_file.delete!.should be_true
      end

      it "purge CDN" do
        CDN.should_receive(:purge).with("/js/token.js")
        cdn_file.delete!
      end
    end

    context "with file isn't present" do
      it "returns false" do
        cdn_file.delete!.should be_false
      end

      it "doesn't purge CDN" do
        CDN.should_not_receive(:purge)
        cdn_file.delete!
      end
    end
  end

end
