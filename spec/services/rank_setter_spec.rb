require 'fast_spec_helper'
require 'page_rankr'
require 'config/vcr'

require 'services/rank_setter'

Site = Class.new unless defined?(Site)

describe RankSetter, :vcr do

  describe '.set_ranks' do
    before do
      expect(Site).to receive(:find).with(site.id) { site }
      expect(site).to receive(:save!)
    end

    context 'site has a hostname' do
      let(:site) { double(id: 1234, hostname: 'sublimevideo.net') }

      it 'updates ranks' do
        expect(site).to receive(:google_rank=).with(6)
        expect(site).to receive(:alexa_rank=).with(91320)

        described_class.set_ranks(site.id)
      end
    end

    context 'site has blank hostname' do
      let(:site) { double(id: 1234, hostname: '') }

      it 'updates ranks' do
        expect(site).to receive(:google_rank=).with(0)
        expect(site).to receive(:alexa_rank=).with(0)

        described_class.set_ranks(site.id)
      end
    end
  end

end
