require 'fast_spec_helper'
require 'page_rankr'
require 'config/vcr'

require 'services/rank_setter'

Site = Class.new unless defined?(Site)

describe RankSetter, :vcr do

  describe '.set_ranks' do
    before do
      Site.should_receive(:find).with(site.id) { site }
      site.should_receive(:save!)
    end

    context 'site has a hostname' do
      let(:site) { double(id: 1234, hostname: 'sublimevideo.net') }

      it 'updates ranks' do
        site.should_receive(:google_rank=).with(6)
        site.should_receive(:alexa_rank=).with(91320)

        described_class.set_ranks(site.id)
      end
    end

    context 'site has blank hostname' do
      let(:site) { double(id: 1234, hostname: '') }

      it 'updates ranks' do
        site.should_receive(:google_rank=).with(0)
        site.should_receive(:alexa_rank=).with(0)

        described_class.set_ranks(site.id)
      end
    end
  end

end
