require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')
require 's3'

require File.expand_path('app/models/addons/custom_logo')
require 'service/addon/custom_logo'

describe Service::Addon::CustomLogo do
  before do
    CDN.stub(:delay) { mock(purge: true) }
  end
  let(:kit)  { stub(identifier: '1', site: stub(token: 'abcd1234')) }
  let(:file) { stub(path: 'foo.png') }
  let(:custom_logo) { Addons::CustomLogo.new(kit, file) }

  describe '#file' do
    it 'delegates to the custom_logo' do
      described_class.new(custom_logo).file.should eq file
    end
  end

  describe '#site' do
    it 'delegates to the custom_logo' do
      described_class.new(custom_logo).site.should eq custom_logo.site
    end
  end

end
