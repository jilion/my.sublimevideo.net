require 'fast_spec_helper'
require 'rails/railtie'
require 'support/fixtures_helpers'
require 'config/carrierwave' # for fog_mock

require 'wrappers/cdn_file'

describe CDNFile, :fog_mock do
  let(:file) { fixture_file('cdn/file.js', 'r') }
  let(:file2) { fixture_file('cdn/file2.js', 'r') }
  let(:path) { 'js/token.js' }
  let(:headers) { {
    'Cache-Control' => 'max-age=60, public', # 2 minutes
    'Content-Type'  => 'text/javascript',
    'x-amz-acl'     => 'public-read'
  } }
  let(:cdn_file) { described_class.new(file, path, headers) }

  describe '#upload!' do
    it 'uploads files' do
      expect(cdn_file).not_to be_present
      cdn_file.upload!
      expect(cdn_file).to be_present
    end

    describe 's3 object(s)' do
      before { cdn_file.upload! }
      let(:bucket) { cdn_file.bucket }

      it 'is public' do
        object_acl = S3Wrapper.fog_connection.get_object_acl(bucket, path).body
        expect(object_acl['AccessControlList']).to include(
          {'Permission'=>'READ', 'Grantee'=>{'URI'=>'http://acs.amazonaws.com/groups/global/AllUsers'}}
        )
      end
      it 'have good content_type public' do
        object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
        expect(object_headers['Content-Type']).to eq 'text/javascript'
      end
      it 'have 5 min max-age cache control' do
        object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
        expect(object_headers['Cache-Control']).to eq 'max-age=60, public'
      end
      it 'have ETag' do
        object_headers = S3Wrapper.fog_connection.head_object(bucket, path).headers
        expect(object_headers['ETag']).to be_present
      end
    end

    describe 'respond' do
      it 'is true when file was not present before' do
        expect(cdn_file.upload!).to be_truthy
      end

      it 'is true when an other file is present' do
        cdn_file.upload!
        cdn_file.file = file2
        expect(cdn_file.upload!).to be_truthy
      end
    end
  end

  describe '#delete!' do
    context 'with file present' do
      before { cdn_file.upload! }

      it 'remove S3 object' do
        cdn_file.delete!
        expect(cdn_file).not_to be_present
      end

      it 'returns true' do
        expect(cdn_file.delete!).to be_truthy
      end
    end
  end

end
