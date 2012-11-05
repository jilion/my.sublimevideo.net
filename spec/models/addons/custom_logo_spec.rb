require 'fast_spec_helper'
require File.expand_path('app/models/addons/custom_logo')

describe Addons::CustomLogo do

  describe 'Validations' do
    it { described_class.new(stub, stub(original_filename: 'test.png', content_type: 'image/png')).should be_valid }
    it { described_class.new(stub, stub(original_filename: 'test.jpg', content_type: 'image/jpg')).should_not be_valid }
  end

  describe '#path' do
    it 'returns the right path to the file' do
      described_class.new(
        stub(identifier: '1', site: stub(token: 'abcd1234')),
        stub(content_type: 'image/jpg')
      ).path.should eq 'a/abcd1234/1/logo-custom@2x.png'
    end
  end

  describe '#url' do
    it 'returns the right url to the file' do
      described_class.new(
        stub(identifier: '1', site: stub(token: 'abcd1234')),
        stub(content_type: 'image/jpg')
      ).url.should eq S3.bucket_url(S3.buckets['sublimevideo']) + 'a/abcd1234/1/logo-custom@2x.png'
    end
  end

end
