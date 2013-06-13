require 'fast_spec_helper'
require 'support/fixtures_helpers'

require 'services/addons/custom_logo_uploader'

describe Addons::CustomLogoUploader do
  let(:kit)  { stub(identifier: '1', site: stub(token: 'abcd1234')) }
  let(:file) { fixture_file('logo-white-big.png') }
  let(:custom_logo) { Addons::CustomLogo.new(file) }

  describe '#file' do
    it 'delegates to the custom_logo' do
      described_class.new(kit, custom_logo).file.should be_a Tempfile
    end
  end

  describe '#width' do
    it 'use the "identify" CLI tool' do

      described_class.new(kit, custom_logo).width.should eq 400
    end
  end

  describe '#height' do
    it 'use the "identify" CLI tool' do
      described_class.new(kit, custom_logo).height.should eq 171
    end
  end

  describe '#site' do
    it 'delegates to the kit' do
      described_class.new(kit, custom_logo).site.should eq kit.site
    end
  end

end
