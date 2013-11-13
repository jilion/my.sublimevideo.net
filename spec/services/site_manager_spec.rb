require 'fast_spec_helper'
require 'rails/railtie'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'models/app'
require 'services/rank_setter'
require 'services/loader_generator'
require 'services/settings_generator'
require 'services/site_manager'

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new(Exception) unless defined?(ActiveRecord::RecordInvalid)

describe SiteManager do
  let(:user)    { double(sites: []) }
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:service) { described_class.new(site) }

  before { allow(Librato).to receive(:increment) }

  describe '.subscribe_site_to_addon' do
    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      expect(Site).to receive(:find) { site }
      expect(SiteManager).to receive(:new).with(site) do |service|
        expect(service).to receive(:update_billable_items).with({}, { 'embed' => 42 })
        service
      end

      described_class.subscribe_site_to_addon(site.id, 'embed', 42)
    end
  end

  describe '#create' do
    before do
      allow(Site).to receive(:transaction).and_yield
      allow(service).to receive(:_create_default_kit!)
      allow(service).to receive(:_set_default_designs)
      allow(service).to receive(:_set_default_addon_plans)
      allow(site).to receive(:loaders_updated_at=)
      allow(site).to receive(:settings_updated_at=)
      allow(site).to receive(:addons_updated_at=)
      allow(site).to receive(:save!)
    end

    it 'saves site twice' do
      expect(site).to receive(:save!).twice

      expect(service.create).to be_truthy
    end

    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      expect(site).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      expect(service.create).to be_falsey
    end

    it 'creates a default kit' do
      expect(service).to receive(:_create_default_kit!)
      expect(service.create).to be_truthy
    end

    it 'sets default app designs and add-ons to site after creation' do
      expect(service).to receive(:_set_default_designs)
      expect(service).to receive(:_set_default_addon_plans)

      expect(service.create).to be_truthy
    end

    it 'touches loaders_updated_at & settings_updated_at' do
      expect(site).to receive(:loaders_updated_at=)
      expect(site).to receive(:settings_updated_at=)

      expect(service.create).to be_truthy
    end

    it 'delays the update of all loader stages' do
      expect(LoaderGenerator).to delay(:update_all_stages!).with(site.id)

      expect(service.create).to be_truthy
    end

    it 'delays the update of all settings types' do
      expect(SettingsGenerator).to delay(:update_all!).with(site.id)

      expect(service.create).to be_truthy
    end

    it 'delays the calculation of google and alexa ranks' do
      expect(RankSetter).to delay(:set_ranks, queue: 'my-low').with(site.id)

      expect(service.create).to be_truthy
    end

    it "increments metrics" do
      expect(Librato).to receive(:increment).with('sites.events', source: 'create')

      expect(service.create).to be_truthy
    end
  end

  describe '#update' do
    let(:attributes) { { hostname: 'test.com' } }
    before do
      allow(Site).to receive(:transaction).and_yield
      allow(site).to receive(:attributes=)
      allow(site).to receive(:settings_updated_at=)
      allow(site).to receive(:save!)
    end

    it 'assignes attributes' do
      expect(site).to receive(:attributes=).with(attributes)

      expect(service.update(attributes)).to be_truthy
    end

    it 'saves site' do
      expect(site).to receive(:save!)

      expect(service.update(attributes)).to be_truthy
    end

    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      expect(site).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      expect(service.update(attributes)).to be_falsey
    end

    it 'touches settings_updated_at' do
      expect(site).to receive(:settings_updated_at=)

      expect(service.update(attributes)).to be_truthy
    end

    it 'delays the update of all settings types' do
      expect(SettingsGenerator).to delay(:update_all!).with(site.id)

      expect(service.update(attributes)).to be_truthy
    end

    it 'increments metrics' do
      expect(Librato).to receive(:increment).with('sites.events', source: 'update')

      expect(service.update(attributes)).to be_truthy
    end
  end

  describe '#update_billable_items' do
    before do
      allow(Site).to receive(:transaction).and_yield
      allow(service).to receive(:_update_design_subscriptions)
      allow(service).to receive(:_update_addon_subscriptions)
      allow(site).to receive(:loaders_updated_at=)
      allow(site).to receive(:settings_updated_at=)
      allow(site).to receive(:addons_updated_at=)
      allow(site).to receive(:save!)
    end

    it 'sets designs billable items' do
      expect(service).to receive(:_update_design_subscriptions).with({ foo: '0' }, {})

      service.update_billable_items({ foo: '0' }, {})
    end

    it 'sets addon plans billable items' do
      expect(service).to receive(:_update_addon_subscriptions).with({ foo: '42' }, {})

      service.update_billable_items({}, { foo: '42' })
    end

    it 'saves site' do
      expect(site).to receive(:save!)

      service.update_billable_items({}, {})
    end

    it 'touches addons_updated_at' do
      expect(site).to receive(:addons_updated_at=)

      service.update_billable_items({}, {})
    end

    it 'delays the update of all loader stages' do
      expect(LoaderGenerator).to delay(:update_all_stages!).with(site.id)

      service.update_billable_items({}, {})
    end

    it 'delays the update of all settings types' do
      expect(SettingsGenerator).to delay(:update_all!).with(site.id)

      service.update_billable_items({}, {})
    end
  end

end
