require 'fast_spec_helper'
require 'active_support/core_ext'

require 'helpers/video_stats_helper'

describe VideoStatsHelper do

  module Helper
    extend VideoStatsHelper

    def self.asset_path(asset)
      asset
    end
  end
  let(:stats) do
    [
      {
        id: 1,
        t: Time.utc(2013, 9, 11, 7).to_s,
        bp: { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 1, 'iex-win' => 5 } },
        co: { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 1 } },
        lo: { 'w' => nil,'e' => 5 },
        st: { 'w' => 2, 'e' => 1 }
      },
      {
        id: 2,
        t: Time.utc(2013, 9, 11, 8).to_s,
        bp: { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 2, 'iex-win' => 5 } },
        co: { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 2 } },
        lo: { 'w' => 4, 'e' => nil },
        st: { 'w' => 3, 'e' => 2 }
      }
    ]
  end

  describe '#video_stats_hourly_loads_for_chart', :focus do
    context 'source == "a"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 5], [Time.utc(2013, 9, 11, 8).to_i, 4]] }

      it { expect(Helper.video_stats_hourly_loads_for_chart(stats, 'a')).to eq expected_result }
    end

    context 'source == "w"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 0], [Time.utc(2013, 9, 11, 8).to_i, 4]] }

      it { expect(Helper.video_stats_hourly_loads_for_chart(stats, 'w')).to eq expected_result }
    end

    context 'source == "e"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 5], [Time.utc(2013, 9, 11, 8).to_i, 0]] }

      it { expect(Helper.video_stats_hourly_loads_for_chart(stats, 'e')).to eq expected_result }
    end
  end

  describe '#video_stats_hourly_starts_for_chart', :focus do
    context 'source == "a"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 3], [Time.utc(2013, 9, 11, 8).to_i, 5]] }

      it { expect(Helper.video_stats_hourly_starts_for_chart(stats, 'a')).to eq expected_result }
    end

    context 'source == "w"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 2], [Time.utc(2013, 9, 11, 8).to_i, 3]] }

      it { expect(Helper.video_stats_hourly_starts_for_chart(stats, 'w')).to eq expected_result }
    end

    context 'source == "e"' do
      let(:expected_result) { [[Time.utc(2013, 9, 11, 7).to_i, 1], [Time.utc(2013, 9, 11, 8).to_i, 2]] }

      it { expect(Helper.video_stats_hourly_starts_for_chart(stats, 'e')).to eq expected_result }
    end
  end

  describe '#video_stats_browser_and_os_stats' do
    context 'source == "a"' do
      let(:expected_result) { { 'iex-win' => { count: 20, percent: 0.8 }, 'saf-osx' => { count: 5, percent: 0.2 } } }

      it { expect(Helper.video_stats_browser_and_os_stats(stats, 'a')).to eq expected_result }
    end

    context 'source == "w"' do
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/12.to_f }, 'saf-osx' => { count: 2, percent: 2/12.to_f } } }

      it { expect(Helper.video_stats_browser_and_os_stats(stats, 'w')).to eq expected_result }
    end

    context 'source == "e"' do
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/13.to_f }, 'saf-osx' => { count: 3, percent: 3/13.to_f } } }

      it { expect(Helper.video_stats_browser_and_os_stats(stats, 'e')).to eq expected_result }
    end
  end

  describe '#video_stats_countries_stats' do
    context 'source == "a"' do
      let(:expected_result) { { 'fr' => { count: 20, percent: 0.8 }, 'ch' => { count: 5, percent: 0.2 } } }

      it { expect(Helper.video_stats_countries_stats(stats, 'a')).to eq expected_result }
    end

    context 'source == "w"' do
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/12.to_f }, 'ch' => { count: 2, percent: 2/12.to_f } } }

      it { expect(Helper.video_stats_countries_stats(stats, 'w')).to eq expected_result }
    end

    context 'source == "e"' do
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/13.to_f }, 'ch' => { count: 3, percent: 3/13.to_f } } }

      it { expect(Helper.video_stats_countries_stats(stats, 'e')).to eq expected_result }
    end
  end

  describe '#video_stats_browser_style' do
    it { expect(Helper.video_stats_browser_style('saf-osx')).to eq 'background-image:url(stats/icons/saf.png);' }
    it { expect(Helper.video_stats_browser_style('saf-iph')).to eq 'background-image:url(stats/icons/saf_mob.png);' }
    it { expect(Helper.video_stats_browser_style('saf-ipa')).to eq 'background-image:url(stats/icons/saf_mob.png);' }
  end

  describe '#video_stats_platform_style' do
    it { expect(Helper.video_stats_platform_style('saf-osx')).to eq 'background-image:url(stats/icons/osx.png);' }
    it { expect(Helper.video_stats_platform_style('saf-iph')).to eq 'background-image:url(stats/icons/iph.png);' }
    it { expect(Helper.video_stats_platform_style('saf-ipa')).to eq 'background-image:url(stats/icons/ipa.png);' }
  end

  describe '#video_stats_country_style' do
    it { expect(Helper.video_stats_country_style('fr')).to eq 'background-image:url(flags/shiny/32/FR.png);' }
  end

  describe '#video_stats_browser_and_os_name' do
    it { expect(Helper.video_stats_browser_and_os_name('saf-osx')).to eq 'Safari - Macintosh' }
    it { expect(Helper.video_stats_browser_and_os_name('foo-bar')).to eq 'foo - bar' }
  end

end
