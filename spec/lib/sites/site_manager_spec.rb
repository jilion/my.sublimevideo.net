require 'fast_spec_helper'
require File.expand_path('lib/sites/site_manager')

Site = Struct.new(:params) unless defined?(Site)

describe Sites::SiteManager do
  let(:user)           { stub(sites: []) }
  let(:site)           { Struct.new(:user, :id).new(nil, 1234) }
  let(:manager)        { described_class.new(site) }
  let(:usage_manager)  { stub }
  let(:delayed_method) { stub }

  describe '.build_site' do
    it 'instantiate a new Sites::SiteManager and returns it' do
      user.sites.should_receive(:new)

      described_class.build_site(user: user).should be_a(described_class)
    end
  end

  describe '#save' do
    before do
      Site.should_receive(:transaction).and_yield
      Addons::AddonshipsManager.stub(:update_addonships_for_site!)
      Sites::RankManager.stub(:delay) { delayed_method }
      Sites::UsageManager.stub(:new) { usage_manager }
      usage_manager.stub(:update_last_30_days_video_views_counters)
      delayed_method.stub(:set_ranks)
    end

    context 'site is valid' do
      before do
        site.should_receive(:save) { true }
      end

      it 'adds default add-ons to site after creation' do
        Addons::AddonshipsManager.should_receive(:update_addonships_for_site!).with(site, logo: 'sublime', support: 'standard')

        manager.save
      end

      it 'delays the calculation of google and alexa ranks' do
        delayed_method.should_receive(:set_ranks).with(site.id)

        manager.save
      end

      it 'updates the last 30 days views counter' do
        Sites::UsageManager.should_receive(:new).with(site) { usage_manager }
        usage_manager.should_receive(:update_last_30_days_video_views_counters)

        manager.save
      end
    end

    context 'site is not valid' do
      before do
        site.should_receive(:save) { false }
      end

      it 'create a new site and save it to the database' do
        manager.save.should be_false
      end

      it 'doesnt add default add-ons to site after creation' do
        Addons::AddonshipsManager.should_not_receive(:update_addonships_for_site!)

        manager.save
      end
    end

  end

end
