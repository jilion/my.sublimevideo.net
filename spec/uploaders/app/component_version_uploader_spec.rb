require 'fast_spec_helper'
require 'zip/zip'
require 'rails/railtie'
require 'fog'
require 'carrierwave'
require 'config/carrierwave'
require 'support/fixtures_helpers'

require 'models/app'
require 'uploaders/app/component_version_uploader'
require 'uploaders/app/component_version_zip_content_uploader'
require 'wrappers/s3_wrapper'

describe App::ComponentVersionUploader, :fog_mock do
  let(:component_version) { stub(
    name: 'app',
    token: 'e',
    version: '2.0.0',
    version_for_url: '2_0_0'
  )}
  let(:zip) { fixture_file('app/e.zip') }
  let(:uploader) { App::ComponentVersionUploader.new(component_version, :zip) }

  before { Rails.stub(:env) { mock('test', to_s: 'test', test?: true) } }
  before { App::ComponentVersionZipContentUploader.stub(:store_zip_content) }

  context "on store!" do
    before { uploader.store!(zip) }

    it "saves zip file on player S3 bucket" do
      uploader.fog_directory.should eq S3Wrapper.buckets['player']
    end

    it "is private" do
      uploader.fog_public.should be_false
    end

    it "has zip content_type" do
      uploader.file.content_type.should eq 'application/zip'
    end

    it "has good filename" do
      uploader.filename.should eq "app-2_0_0.zip"
    end
  end

  describe "after store callback" do
    it "uploads zip content on sublimevideo S3 bucket" do
      App::ComponentVersionZipContentUploader.should_receive(:store_zip_content).with(
        kind_of(String),
        Pathname.new('c/e/2.0.0/')
      )
      uploader.store!(zip)
    end
  end

  describe "after remove callback" do
    before { uploader.store!(zip) }

    it "remove zip content on sublimevideo S3 bucket" do
      App::ComponentVersionZipContentUploader.should_receive(:remove_zip_content).with(
        Pathname.new('c/e/2.0.0/')
      )
      uploader.remove!
    end
  end

end
