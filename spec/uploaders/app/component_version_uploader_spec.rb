require 'fast_spec_helper'
require 'zip'
require 'rails/railtie'
require 'fog'
require 'carrierwave'
require 'config/carrierwave'
require 'support/fixtures_helpers'

require 'uploaders/app/component_version_uploader'

describe App::ComponentVersionUploader, :fog_mock do
  let(:component_version) { double(
    name: 'app',
    token: 'e',
    version: '2.0.0',
    version_for_url: '2_0_0'
  )}
  let(:zip) { fixture_file('app/e.zip') }
  let(:uploader) { App::ComponentVersionUploader.new(component_version, :zip) }
  let(:zip_content_uploader) { double(App::ComponentVersionUploader).as_null_object }

  before { allow(Rails).to receive(:env) { double('test', to_s: 'test', test?: true) } }
  before { allow(App::ComponentVersionZipContentUploader).to receive(:new) { zip_content_uploader } }

  context 'on store!' do
    before { uploader.store!(zip) }

    it 'saves zip file on player S3 bucket' do
      expect(uploader.fog_directory).to eq S3Wrapper.buckets[:player]
    end

    it 'is private' do
      expect(uploader.fog_public).to be_falsey
    end

    it 'has zip content_type' do
      expect(uploader.file.content_type).to eq 'application/zip'
    end

    it 'has good filename' do
      expect(uploader.filename).to eq 'app-2_0_0.zip'
    end
  end

  describe 'after store callback' do
    it 'uploads zip content on sublimevideo S3 bucket' do
      expect(App::ComponentVersionZipContentUploader).to receive(:new).with(Pathname.new('c/e/2.0.0/')) { |mock|
        expect(mock).to receive(:store_zip_content).with(kind_of(String))
        mock
      }
      uploader.store!(zip)
    end
  end

  describe 'after remove callback' do
    before { uploader.store!(zip) }

    it 'remove zip content on sublimevideo S3 bucket' do
      expect(App::ComponentVersionZipContentUploader).to receive(:new).with(Pathname.new('c/e/2.0.0/')) { |mock|
        expect(mock).to receive(:remove_zip_content)
        mock
      }
      uploader.remove!
    end
  end

end
