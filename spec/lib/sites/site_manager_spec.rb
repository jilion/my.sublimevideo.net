require 'fast_spec_helper'
require File.expand_path('lib/sites/site_manager')

Site = Class.new unless defined?(Site)
Addons = Module.new unless defined?(Addons)
Addons::AddonshipManager = Class.new unless defined?(Addons::AddonshipManager)
Sites::RankManager = Class.new unless defined?(Sites::RankManager)

describe Sites::SiteManager do
  let(:user)           { stub(sites: []) }
  let(:site)           { Struct.new(:user, :id).new(nil, 1234) }
  let(:manager)        { described_class.new(user) }
  let(:delayed_method) { stub }

  describe '.create' do
    before do
      Site.should_receive(:transaction).and_yield
      Addons::AddonshipManager.stub(:update_addonships_for_site!)
      Sites::RankManager.stub(:delay) { delayed_method }
      delayed_method.stub(:set_ranks)
    end

    context 'site is valid' do
      before do
        site.should_receive(:save) { true }
      end

      it 'set the site user and save it to the database' do
        site.user.should be_nil

        manager.create(site).should be_true

        site.user.should eq user
      end

      it 'adds default add-ons to site after creation' do
        Addons::AddonshipManager.should_receive(:update_addonships_for_site!).with(site, logo: 'sublime', support: 'standard')

        manager.create(site)
      end

      it 'delays the calculation of google and alexa ranks' do
        Sites::RankManager.should_receive(:delay) { delayed_method }
        delayed_method.should_receive(:set_ranks).with(site.id)

        manager.create(site)
      end
    end

    context 'site is not valid' do
      before do
        site.should_receive(:save) { false }
      end

      it 'create a new site and save it to the database' do
        manager.create(site).should be_false
      end

      it 'doesnt add default add-ons to site after creation' do
        Addons::AddonshipManager.should_not_receive(:update_addonships_for_site!)

        manager.create(site)
      end
    end

  end

end
