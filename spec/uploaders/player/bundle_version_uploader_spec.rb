require 'fast_spec_helper'
require 'zip/zip'
require 'rails/railtie'
require 'fog'
require 'carrierwave'
require File.expand_path('spec/config/carrierwave')
require File.expand_path('spec/support/fixtures_helpers')

require File.expand_path('config/initializers/carrierwave')
require File.expand_path('app/models/player')
require File.expand_path('app/uploaders/player/bundle_version_uploader')

describe Player::BundleVersionUploader, :fog_mock do
  let(:bundle_version) { stub(
    name: 'app',
    token: 'bA',
    version: '2.0.0'
  )}
  let(:zip) { fixture_file('player/bA.zip') }
  let(:uploader) { Player::BundleVersionUploader.new(bundle_version, :zip) }

  # before { Player::ZipUploader.stub(:upload_zip_content) }

  context "on store!" do
    before { uploader.store!(zip) }

    it "saves zip file on player S3 bucket" do
      uploader.fog_directory.should eq S3.buckets['player']
    end

    it "is private" do
      uploader.fog_public.should be_false
    end

    it "has zip content_type" do
      uploader.file.content_type.should eq 'application/zip'
    end

    it "has good filename" do
      uploader.filename.should eq "app-2.0.0.zip"
    end
  end

  describe "process" do
    it "uploads zip content on sublimevideo S3 bucket" do
      # Player::ZipUploader.should_receive(:upload_zip_content).with(
      #   kind_of(CarrierWave::SanitizedFile),
      #   Pathname.new('f/bA/2.0.0')
      # )
      # uploader.store!(zip)
    end
  end

end
