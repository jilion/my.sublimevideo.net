require 'spec_helper'

describe UrlsHelper do

  describe '.cdn_url' do
    context 'Rails.env == development' do
      before { allow(Rails).to receive(:env).and_return('development') }

      it { expect(helper.cdn_url('foo')).to eq 'http://s3.amazonaws.com/dev.sublimevideo/foo' }
      it { expect(helper.cdn_url('/foo')).to eq 'http://s3.amazonaws.com/dev.sublimevideo/foo' }
      it { expect(helper.cdn_url('foo/')).to eq 'http://s3.amazonaws.com/dev.sublimevideo/foo/' }
      it { expect(helper.cdn_url('/foo.js')).to eq 'http://s3.amazonaws.com/dev.sublimevideo/foo.js' }
    end

    context 'Rails.env == staging' do
      before { allow(Rails).to receive(:env).and_return('staging') }

      it { expect(helper.cdn_url('foo')).to eq 'http://cdn.sublimevideo-staging.net/foo' }
      it { expect(helper.cdn_url('/foo')).to eq 'http://cdn.sublimevideo-staging.net/foo' }
      it { expect(helper.cdn_url('foo/')).to eq 'http://cdn.sublimevideo-staging.net/foo/' }
      it { expect(helper.cdn_url('/foo.js')).to eq 'http://cdn.sublimevideo-staging.net/foo.js' }
    end

    %w[test production].each do |env|
      context "Rails.env == #{env}" do
        before { allow(Rails).to receive(:env).and_return(env) }

        it { expect(helper.cdn_url('foo')).to eq '//cdn.sublimevideo.net/foo' }
        it { expect(helper.cdn_url('/foo')).to eq '//cdn.sublimevideo.net/foo' }
        it { expect(helper.cdn_url('foo/')).to eq '//cdn.sublimevideo.net/foo/' }
        it { expect(helper.cdn_url('/foo.js')).to eq '//cdn.sublimevideo.net/foo.js' }
      end
    end
  end

  describe '.cdn_path_from_full_url' do
    context 'Rails.env == development' do
      before { allow(Rails).to receive(:env).and_return('development') }

      it { expect(helper.cdn_path_from_full_url('http://s3.amazonaws.com/dev.sublimevideo/foo')).to eq 'foo' }
      it { expect(helper.cdn_path_from_full_url('http://s3.amazonaws.com/dev.sublimevideo/foo/')).to eq 'foo/' }
      it { expect(helper.cdn_path_from_full_url('http://s3.amazonaws.com/dev.sublimevideo/foo.js')).to eq 'foo.js' }
    end

    context 'Rails.env == staging' do
      before { allow(Rails).to receive(:env).and_return('staging') }

      it { expect(helper.cdn_path_from_full_url('http://cdn.sublimevideo-staging.net/foo')).to eq 'foo' }
      it { expect(helper.cdn_path_from_full_url('http://cdn.sublimevideo-staging.net/foo/')).to eq 'foo/' }
      it { expect(helper.cdn_path_from_full_url('http://cdn.sublimevideo-staging.net/foo.js')).to eq 'foo.js' }
    end

    %w[test production].each do |env|
      context "Rails.env == #{env}" do
        before { allow(Rails).to receive(:env).and_return(env) }

        it { expect(helper.cdn_path_from_full_url('//cdn.sublimevideo.net/foo')).to eq 'foo' }
        it { expect(helper.cdn_path_from_full_url('//cdn.sublimevideo.net/foo/')).to eq 'foo/' }
        it { expect(helper.cdn_path_from_full_url('//cdn.sublimevideo.net/foo.js')).to eq 'foo.js' }
      end
    end
  end

end
