require 'fast_spec_helper'
require File.expand_path('lib/services/sites/manager')

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)

describe Services::Sites::Manager do
  let(:user)              { stub(sites: []) }
  let(:site)              { Struct.new(:user, :id).new(nil, 1234) }
  let(:manager)           { described_class.new(site) }
  let(:delayed_method)    { stub }

  describe '.build_site' do
    it 'instantiate a new Services::Sites::Manager and returns it' do
      user.sites.should_receive(:new)

      described_class.build_site(user: user).should be_a(described_class)
    end
  end

  describe '#save' do
    before do
      Site.should_receive(:transaction).and_yield
      Services::Sites::Rank.stub(:delay) { delayed_method }
      manager.stub(:set_default_app_designs) { true }
      manager.stub(:set_default_addon_plans) { true }
      delayed_method.stub(:set_ranks) { true }
    end

    context 'site is valid' do
      before do
        site.should_receive(:save).twice { true }
      end

      it 'adds default app designs to site after creation' do
        manager.should_receive(:set_default_app_designs)

        manager.save
      end

      it 'adds default add-ons to site after creation' do
        manager.should_receive(:set_default_addon_plans)

        manager.save
      end

      it 'delays the calculation of google and alexa ranks' do
        Services::Sites::Rank.should_receive(:delay) { delayed_method }
        delayed_method.should_receive(:set_ranks).with(site.id)

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
        Services::Sites::Addonship.should_not_receive(:new)

        manager.save
      end
    end

  end

end
