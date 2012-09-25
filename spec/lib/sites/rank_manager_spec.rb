require 'fast_spec_helper'
require 'config/vcr'
require File.expand_path('lib/sites/rank_manager')

Site = Struct.new(:id, :hostname, :google_rank, :alexa_rank) unless defined?(Site)

describe Sites::RankManager do

  describe '.set_ranks' do
    use_vcr_cassette 'sites/ranks'
    before do
      Site.should_receive(:find) { site }
      site.should_receive(:save)
    end

    context 'site has a hostname' do
      let(:site) { Site.new(1234, 'sublimevideo.net') }

      it 'updates ranks' do
        described_class.set_ranks(site.id)

        site.google_rank.should eq 6
        site.alexa_rank.should eq 91386
      end
    end

    context 'site has blank hostname' do
      let(:site) { Site.new(1234, '') }

      it 'updates ranks' do
        described_class.set_ranks(site.id)

        site.google_rank.should eq 0
        site.alexa_rank.should eq 0
      end
    end
  end

end
