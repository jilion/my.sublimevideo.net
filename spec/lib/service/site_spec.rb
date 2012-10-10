require 'fast_spec_helper'
require File.expand_path('lib/service/site')

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)

describe Service::Site do
  let(:user)           { stub(sites: []) }
  let(:site)           { Struct.new(:user, :id).new(nil, 1234) }
  let(:service)        { described_class.new(site) }
  let(:delayed_method) { stub }

  describe '.build_site' do
    it 'instantiate a new Service::Site and returns it' do
      user.sites.should_receive(:new)

      described_class.build_site(user: user).should be_a(described_class)
    end
  end

  describe '#initial_save' do
    before do
      Site.should_receive(:transaction).and_yield
      Service::Rank.stub(:delay) { delayed_method }
      service.stub(:set_default_app_designs) { true }
      service.stub(:set_default_addon_plans) { true }
      delayed_method.stub(:set_ranks) { true }
    end

    context 'site is valid' do
      before do
        site.should_receive(:save).twice { true }
      end

      it 'adds default app designs and add-ons to site after creation' do
        service.should_receive(:set_default_app_designs)
        service.should_receive(:set_default_addon_plans)

        service.initial_save
      end

      it 'delays the calculation of google and alexa ranks' do
        Service::Rank.should_receive(:delay) { delayed_method }
        delayed_method.should_receive(:set_ranks).with(site.id)

        service.initial_save
      end
    end

    context 'site is not valid' do
      before do
        site.should_receive(:save) { false }
      end

      it 'create a new site and save it to the database' do
        service.initial_save.should be_false
      end

      it 'doesnt add default app designs and add-ons to site after creation' do
        service.should_not_receive(:set_default_app_designs)
        service.should_not_receive(:set_default_addon_plans)

        service.initial_save
      end
    end
  end

end
