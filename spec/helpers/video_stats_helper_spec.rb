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
    it { expect(Helper.video_stats_country_style('fr')).to eq 'background-image:url(flags/FR.png);' }
  end

  describe '#video_stats_browser_and_os_name' do
    it { expect(Helper.video_stats_browser_and_os_name('saf-osx')).to eq 'Safari<br />Macintosh' }
    it { expect(Helper.video_stats_browser_and_os_name('foo-bar')).to eq 'foo<br />bar' }
  end

end
