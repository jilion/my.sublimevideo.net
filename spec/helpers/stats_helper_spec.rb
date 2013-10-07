require 'spec_helper'

describe StatsHelper do

  describe "pusher_channel" do
    let(:site) { double(token: 'site_token') }
    let(:video_tag) { double(uid: 'video_uid') }

    context "with only @site present" do
      before { assign(:site, site) }

      specify { expect(helper.pusher_channel).to eq 'private-site_token' }
    end

    context "with @site and @video_tag present" do
      before {
        assign(:site, site)
        assign(:video_tag, video_tag)
      }

      specify { expect(helper.pusher_channel).to eq 'private-site_token.video_uid' }
    end
  end

  describe '#stats_hours_range_select' do
    it { expect(helper.stats_hours_range_select(24)).to eq({
      (30.days / 1.hour) => '30 days',
      (90.days / 1.hour) => '90 days',
      (365.days / 1.hour) => '365 days'
    }) }

    it { expect(helper.stats_hours_range_select(30*24)).to eq({
      24 => '24 hours',
      (90.days / 1.hour) => '90 days',
      (365.days / 1.hour) => '365 days'
    }) }

    it { expect(helper.stats_hours_range_select(90*24)).to eq({
      24 => '24 hours',
      (30.days / 1.hour) => '30 days',
      (365.days / 1.hour) => '365 days'
    }) }

    it { expect(helper.stats_hours_range_select(365*24)).to eq({
      24 => '24 hours',
      (30.days / 1.hour) => '30 days',
      (90.days / 1.hour) => '90 days'
    }) }
  end

  describe '#stats_source_select' do
    it { expect(helper.stats_source_select('a')).to eq({
      'w' => 'your site',
      'e' => 'other sites'
    }) }

    it { expect(helper.stats_source_select('w')).to eq({
      'a' => 'all sources',
      'e' => 'other sites'
    }) }

    it { expect(helper.stats_source_select('e')).to eq({
      'a' => 'all sources',
      'w' => 'your site'
    }) }
  end

  describe '#stats_hours_or_days' do
    it { expect(helper.stats_hours_or_days(1)).to eq '1 hour' }
    it { expect(helper.stats_hours_or_days(23)).to eq '23 hours' }
    it { expect(helper.stats_hours_or_days(24)).to eq '24 hours' }
    it { expect(helper.stats_hours_or_days(25)).to eq '1 day' }
    it { expect(helper.stats_hours_or_days(48)).to eq '2 days' }
  end

  describe '#stats_sources_for_export_text' do
    it { expect(helper.stats_sources_for_export_text('a')).to eq 'anywhere (on your site and external sources altogether)' }
    it { expect(helper.stats_sources_for_export_text('w')).to eq 'on your site only' }
    it { expect(helper.stats_sources_for_export_text('e')).to eq 'on external sources only' }
  end

  describe '#stats_browser_style' do
    it { expect(helper.stats_browser_style('saf-osx')).to eq 'background-image:url(/assets/stats/icons/saf.png);' }
    it { expect(helper.stats_browser_style('saf-iph')).to eq 'background-image:url(/assets/stats/icons/saf_mob.png);' }
    it { expect(helper.stats_browser_style('saf-ipa')).to eq 'background-image:url(/assets/stats/icons/saf_mob.png);' }
  end

  describe '#stats_platform_style' do
    it { expect(helper.stats_platform_style('saf-osx')).to eq 'background-image:url(/assets/stats/icons/osx.png);' }
    it { expect(helper.stats_platform_style('saf-iph')).to eq 'background-image:url(/assets/stats/icons/iph.png);' }
    it { expect(helper.stats_platform_style('saf-ipa')).to eq 'background-image:url(/assets/stats/icons/ipa.png);' }
  end

  describe '#stats_country_name' do
    it { expect(helper.stats_country_name('fr')).to eq 'France' }
    it { expect(helper.stats_country_name('gb')).to eq 'United Kingdom' }
    it { expect(helper.stats_country_name('gp')).to eq 'Guadeloupe' }
    it { expect(helper.stats_country_name('re')).to eq 'Réunion' }
    it { expect(helper.stats_country_name('io')).to eq 'British Indian Ocean Territory' }
    it { expect(helper.stats_country_name('unknown')).to eq 'Unknown' }
  end

  describe '#stats_country_style' do
    it { expect(helper.stats_country_style('fr')).to eq 'background-image:url(/assets/flags/FR.png);' }
    it { expect(helper.stats_country_style('gb')).to eq 'background-image:url(/assets/flags/GB.png);' }
    it { expect(helper.stats_country_style('gp')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
    it { expect(helper.stats_country_style('re')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
    it { expect(helper.stats_country_style('io')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
    it { expect(helper.stats_country_style('unknown')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
  end

  describe '#stats_browser_and_os_name' do
    it { expect(helper.stats_browser_and_os_name('saf-osx')).to eq 'Safari<br />Macintosh' }
    it { expect(helper.stats_browser_and_os_name('foo-bar')).to eq 'foo<br />bar' }
  end

  describe '#stats_browser_or_os_name' do
    it { expect(helper.stats_browser_and_os_name('saf')).to eq 'Safari' }
    it { expect(helper.stats_browser_and_os_name('osx')).to eq 'Macintosh' }
    it { expect(helper.stats_browser_and_os_name('foo')).to eq 'foo' }
  end

end
