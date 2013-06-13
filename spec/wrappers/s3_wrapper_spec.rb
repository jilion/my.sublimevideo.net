require 'fast_spec_helper'

require 'wrappers/s3_wrapper'

describe S3Wrapper do

  describe '.bucket_url' do
    it { described_class.bucket_url('foo').should eq 'https://s3.amazonaws.com/foo/' }
  end

  describe '.buckets' do
    it 'returns bucket name' do
      described_class.buckets[:sublimevideo].should eq 'dev.sublimevideo'
    end
  end

end
