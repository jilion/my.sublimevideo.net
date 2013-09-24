require 'fast_spec_helper'
require 'support/fixtures_helpers'

require 'services/addons/custom_logo_uploader'

describe Addons::CustomLogoUploader do
  let(:kit)  { double(identifier: '1', site: double(token: 'abcd1234')) }
  let(:file) { fixture_file('logo-white-big.png') }
  let(:custom_logo) { Addons::CustomLogo.new(file) }
  let(:uploader) { described_class.new(kit, custom_logo) }

  describe '#site' do
    it 'delegates to the kit' do
      uploader.site.should eq kit.site
    end
  end

  describe '#file' do
    it 'returns a Tempfile' do
      uploader.file.should be_a Tempfile
    end
  end

  describe '#cdn_file' do
    it 'returns a CDNFile' do
      uploader.cdn_file.should be_a CDNFile
    end
  end

  describe '#width' do
    it 'use the "identify" CLI tool' do
      uploader.width.should eq 400
    end
  end

  describe '#height' do
    it 'use the "identify" CLI tool' do
      uploader.height.should eq 171
    end
  end

  describe '#path' do
    it 'use the "identify" CLI tool' do
      uploader.path.should eq "a/#{kit.site.token}/#{kit.identifier}/logo-custom-#{uploader.width}x#{uploader.height}-#{Time.now.to_i}@2x.png"
    end
  end

end
