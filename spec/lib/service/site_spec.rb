require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('app/models/app')
require File.expand_path('lib/service/site')

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)

describe Service::Site do
  let(:user)           { stub(sites: []) }
  let(:site)           { Struct.new(:user, :id).new(nil, 1234) }
  let(:service)        { described_class.new(site) }

  describe '#create' do
    before do
      Site.stub(:transaction).and_yield
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

    it 'sets default app designs and add-ons to site after creation' do
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
      Service::Loader.should delay(:update_all_stages!).with(site.id)
      service.create
    end

    it 'delays the update of all settings types' do
      Service::Settings.should delay(:update_all_types!).with(site.id)
      service.create
    end

    it 'delays the calculation of google and alexa ranks' do
      Service::Rank.should delay(:set_ranks, queue: 'low').with(site.id)
      service.create
    end
  end

  describe "#update" do
    let(:attributes) { { hostname: 'test.com' } }
    before do
      Site.stub(:transaction).and_yield
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
      Service::Settings.should delay(:update_all_types!).with(site.id)
      service.update(attributes)
    end
  end

end
