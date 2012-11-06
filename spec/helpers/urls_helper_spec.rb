require 'spec_helper'

describe UrlsHelper do

  describe '.cdn_url' do
    context 'Rails.env == development' do
      before { Rails.stub(env: 'development') }

      it { helper.cdn_url('foo').should eq 'http://s3.amazonaws.com/dev.sublimevideo/foo' }
      it { helper.cdn_url('/foo').should eq 'http://s3.amazonaws.com/dev.sublimevideo/foo' }
      it { helper.cdn_url('foo/').should eq 'http://s3.amazonaws.com/dev.sublimevideo/foo/' }
      it { helper.cdn_url('/foo.js').should eq 'http://s3.amazonaws.com/dev.sublimevideo/foo.js' }
    end

    context 'Rails.env == staging' do
      before { Rails.stub(env: 'staging') }

      it { helper.cdn_url('foo').should eq 'http://cdn.sublimevideo.net-staging/foo' }
      it { helper.cdn_url('/foo').should eq 'http://cdn.sublimevideo.net-staging/foo' }
      it { helper.cdn_url('foo/').should eq 'http://cdn.sublimevideo.net-staging/foo/' }
      it { helper.cdn_url('/foo.js').should eq 'http://cdn.sublimevideo.net-staging/foo.js' }
    end

    %w[test production].each do |env|
      context "Rails.env == #{env}" do
        before { Rails.stub(env: env) }

        it { helper.cdn_url('foo').should eq '//cdn.sublimevideo.net/foo' }
        it { helper.cdn_url('/foo').should eq '//cdn.sublimevideo.net/foo' }
        it { helper.cdn_url('foo/').should eq '//cdn.sublimevideo.net/foo/' }
        it { helper.cdn_url('/foo.js').should eq '//cdn.sublimevideo.net/foo.js' }
      end
    end
  end

end
