require 'fast_spec_helper'
require 'rails/railtie'

require File.expand_path('app/models/app')
require File.expand_path('lib/service/site')

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)

describe Service::Site do
  let(:user)           { stub(sites: []) }
  let(:site)           { Struct.new(:user, :id).new(nil, 1234) }
  let(:service)        { described_class.new(site) }
  let(:delayed_method) { stub.as_null_object }

  describe '#create' do
    before do
      Site.stub(:transaction).and_yield
      Service::Loader.stub(:delay) { delayed_method }
      Service::Settings.stub(:delay) { delayed_method }
      Service::Rank.stub(:delay) { delayed_method }
      service.stub(:create_default_kit!)
      service.stub(:set_default_app_designs)
      service.stub(:set_default_addon_plans)
      site.stub(:save!)
      site.stub(:loaders_updated_at=)
      site.stub(:settings_updated_at=)
    end

    it 'saves site twice' do
      site.should_receive(:save!).twice
      service.create
    end

    it 'creates a default kit' do
      service.should_receive(:create_default_kit!)
      service.create
    end

    it 'adds default app designs and add-ons to site after creation' do
      service.should_receive(:set_default_app_designs)
      service.should_receive(:set_default_addon_plans)
      service.create
    end

    it 'touches loaders_updated_at & settings_updated_at' do
      site.should_receive(:loaders_updated_at=)
      site.should_receive(:settings_updated_at=)
      service.create
    end

    it 'delays the update of all loader stages' do
      delayed_method.should_receive(:update_all_stages!).with(site.id)
      service.create
    end

    it 'delays the update of all settings types' do
      delayed_method.should_receive(:update_all_types!).with(site.id)
      service.create
    end

    it 'delays the calculation of google and alexa ranks' do
      delayed_method.should_receive(:set_ranks).with(site.id)
      service.create
    end
  end

  describe "#update" do
    let(:attributes) { { hostname: 'test.com' } }
    before do
      Site.stub(:transaction).and_yield
      Service::Settings.stub(:delay) { delayed_method }
      site.stub(:attributes=)
      site.stub(:settings_updated_at=)
      site.stub(:save!)
    end

    it 'assignes attributes' do
      site.should_receive(:attributes=).with(attributes)
      service.update(attributes)
    end

    it 'saves site' do
      site.should_receive(:save!)
      service.update(attributes)
    end

    it 'touches settings_updated_at' do
      site.should_receive(:settings_updated_at=)
      service.update(attributes)
    end

    it 'delays the update of all settings types' do
      delayed_method.should_receive(:update_all_types!).with(site.id)
      service.update(attributes)
    end
  end

end
