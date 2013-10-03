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

  describe '#video_stats_options_for_date_range_select' do
    it { expect(helper.video_stats_options_for_date_range_select(24)).to eq(
      "<option selected=\"selected\" value=\"24\">Last 24 hours</option>" \
      "\n<option value=\"720\">Last 30 days</option>" \
      "\n<option value=\"2160\">Last 90 days</option>" \
      "\n<option value=\"8760\">Last 365 days</option>") }

    it { expect(helper.video_stats_options_for_date_range_select(30*24)).to eq(
      "<option value=\"24\">Last 24 hours</option>" \
      "\n<option selected=\"selected\" value=\"720\">Last 30 days</option>" \
      "\n<option value=\"2160\">Last 90 days</option>" \
      "\n<option value=\"8760\">Last 365 days</option>") }

    it { expect(helper.video_stats_options_for_date_range_select(90*24)).to eq(
      "<option value=\"24\">Last 24 hours</option>" \
      "\n<option value=\"720\">Last 30 days</option>" \
      "\n<option selected=\"selected\" value=\"2160\">Last 90 days</option>" \
      "\n<option value=\"8760\">Last 365 days</option>") }

    it { expect(helper.video_stats_options_for_date_range_select(365*24)).to eq(
      "<option value=\"24\">Last 24 hours</option>" \
      "\n<option value=\"720\">Last 30 days</option>" \
      "\n<option value=\"2160\">Last 90 days</option>" \
      "\n<option selected=\"selected\" value=\"8760\">Last 365 days</option>") }
  end

  describe '#video_stats_options_for_source_select' do
    it { expect(helper.video_stats_options_for_source_select('a')).to eq(
      "<option selected=\"selected\" value=\"a\">All sources</option>" \
      "\n<option value=\"w\">Your website</option>" \
      "\n<option value=\"e\">External websites</option>") }

    it { expect(helper.video_stats_options_for_source_select('w')).to eq(
      "<option value=\"a\">All sources</option>" \
      "\n<option selected=\"selected\" value=\"w\">Your website</option>" \
      "\n<option value=\"e\">External websites</option>") }

    it { expect(helper.video_stats_options_for_source_select('e')).to eq(
      "<option value=\"a\">All sources</option>" \
      "\n<option value=\"w\">Your website</option>" \
      "\n<option selected=\"selected\" value=\"e\">External websites</option>") }
  end

  describe '#video_stats_hours_or_days' do
    it { expect(helper.video_stats_hours_or_days(1)).to eq '1 hour' }
    it { expect(helper.video_stats_hours_or_days(23)).to eq '23 hours' }
    it { expect(helper.video_stats_hours_or_days(24)).to eq '24 hours' }
    it { expect(helper.video_stats_hours_or_days(25)).to eq '1 day' }
    it { expect(helper.video_stats_hours_or_days(48)).to eq '2 days' }
  end

  describe '#video_stats_sources_for_export_text' do
    it { expect(helper.video_stats_sources_for_export_text('a')).to eq 'anywhere (on your website and external websites altogether)' }
    it { expect(helper.video_stats_sources_for_export_text('w')).to eq 'on your website only' }
    it { expect(helper.video_stats_sources_for_export_text('e')).to eq 'on external websites only' }
  end

  describe '#video_stats_browser_style' do
    it { expect(helper.video_stats_browser_style('saf-osx')).to eq 'background-image:url(/assets/stats/icons/saf.png);' }
    it { expect(helper.video_stats_browser_style('saf-iph')).to eq 'background-image:url(/assets/stats/icons/saf_mob.png);' }
    it { expect(helper.video_stats_browser_style('saf-ipa')).to eq 'background-image:url(/assets/stats/icons/saf_mob.png);' }
  end

  describe '#video_stats_platform_style' do
    it { expect(helper.video_stats_platform_style('saf-osx')).to eq 'background-image:url(/assets/stats/icons/osx.png);' }
    it { expect(helper.video_stats_platform_style('saf-iph')).to eq 'background-image:url(/assets/stats/icons/iph.png);' }
    it { expect(helper.video_stats_platform_style('saf-ipa')).to eq 'background-image:url(/assets/stats/icons/ipa.png);' }
  end

  describe '#video_stats_country_name' do
    it { expect(helper.video_stats_country_name('fr')).to eq 'France' }
    it { expect(helper.video_stats_country_name('uk')).to eq 'United Kingdom' }
    it { expect(helper.video_stats_country_name('gb')).to eq 'United Kingdom' }
    it { expect(helper.video_stats_country_name('a1')).to eq 'Unknown' }
    it { expect(helper.video_stats_country_name('a2')).to eq 'Unknown' }
    it { expect(helper.video_stats_country_name('o1')).to eq 'Unknown' }
  end

  describe '#video_stats_country_style' do
    it { expect(helper.video_stats_country_style('fr')).to eq 'background-image:url(/assets/flags/FR.png);' }
    it { expect(helper.video_stats_country_style('uk')).to eq 'background-image:url(/assets/flags/GB.png);' }
    it { expect(helper.video_stats_country_style('gb')).to eq 'background-image:url(/assets/flags/GB.png);' }
    it { expect(helper.video_stats_country_style('a1')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
    it { expect(helper.video_stats_country_style('a2')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
    it { expect(helper.video_stats_country_style('o1')).to eq 'background-image:url(/assets/flags/UNKNOWN.png);' }
  end

  describe '#video_stats_browser_and_os_name' do
    it { expect(helper.video_stats_browser_and_os_name('saf-osx')).to eq 'Safari<br />Macintosh' }
    it { expect(helper.video_stats_browser_and_os_name('foo-bar')).to eq 'foo<br />bar' }
  end

  describe '#video_stats_browser_or_os_name' do
    it { expect(helper.video_stats_browser_and_os_name('saf')).to eq 'Safari' }
    it { expect(helper.video_stats_browser_and_os_name('osx')).to eq 'Macintosh' }
    it { expect(helper.video_stats_browser_and_os_name('foo')).to eq 'foo' }
  end

end
