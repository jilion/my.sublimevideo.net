require 'fast_spec_helper'
require 'config/vcr'
require File.expand_path('lib/service/rank')

describe Service::Rank do
  unless defined?(Site)
    before do
      Site = Class.new
    end
    after { Object.send(:remove_const, :Site) }
  end

  describe '.set_ranks' do
    use_vcr_cassette 'sites/ranks'
    before do
      Site.should_receive(:find).with(site.id) { site }
      site.should_receive(:save!)
    end

    context 'site has a hostname' do
      let(:site) { stub(id: 1234, hostname: 'sublimevideo.net') }

      it 'updates ranks' do
        site.should_receive(:google_rank=).with(6)
        site.should_receive(:alexa_rank=).with(91386)

        described_class.set_ranks(site.id)
      end
    end

    context 'site has blank hostname' do
      let(:site) { stub(id: 1234, hostname: '') }

      it 'updates ranks' do
        site.should_receive(:google_rank=).with(0)
        site.should_receive(:alexa_rank=).with(0)

        described_class.set_ranks(site.id)
      end
    end
  end

end
