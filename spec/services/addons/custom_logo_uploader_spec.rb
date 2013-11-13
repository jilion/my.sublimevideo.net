require 'fast_spec_helper'
require 'timecop'
require 'support/fixtures_helpers'

require 'services/addons/custom_logo_uploader'

describe Addons::CustomLogoUploader do
  let(:kit)  { double(identifier: '1', site: double(token: 'abcd1234')) }
  let(:file) { fixture_file('logo-white-big.png') }
  let(:custom_logo) { Addons::CustomLogo.new(file) }
  let(:uploader) { described_class.new(kit, custom_logo) }

  describe '#site' do
    it 'delegates to the kit' do
      expect(uploader.site).to eq kit.site
    end
  end

  describe '#file' do
    it 'returns a Tempfile' do
      expect(uploader.file).to be_a Tempfile
    end
  end

  describe '#cdn_file' do
    it 'returns a CDNFile' do
      expect(uploader.cdn_file).to be_a CDNFile
    end
  end

  describe '#width' do
    it 'use the "identify" CLI tool' do
      expect(uploader.width).to eq 400
    end
  end

  describe '#height' do
    it 'use the "identify" CLI tool' do
      expect(uploader.height).to eq 171
    end
  end

  describe '#path' do
    it 'use the "identify" CLI tool' do
      Timecop.freeze do
        expect(uploader.path).to eq "a/#{kit.site.token}/#{kit.identifier}/logo-custom-#{uploader.width}x#{uploader.height}-#{Time.now.to_i}@2x.png"
      end
    end
  end

end
