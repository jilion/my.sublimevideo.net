require 'fast_spec_helper'

require 'wrappers/s3_wrapper'

describe S3Wrapper do

  describe '.bucket_url' do
    it { expect(described_class.bucket_url('foo')).to eq 'https://s3.amazonaws.com/foo/' }
  end

  describe '.buckets' do
    it 'returns bucket name' do
      expect(described_class.buckets[:sublimevideo]).to eq 'dev.sublimevideo'
    end
  end

end
