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

  before { Librato.stub(:increment) }

  describe '.subscribe_site_to_addon' do
    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      Site.should_receive(:find) { site }
      SiteManager.should_receive(:new).with(site) do |service|
        service.should_receive(:update_billable_items).with({}, { 'embed' => 42 })
        service
      end

      described_class.subscribe_site_to_addon(site.id, 'embed', 42)
    end
  end

  describe '#create' do
    before do
      Site.stub(:transaction).and_yield
      service.stub(:_create_default_kit!)
      service.stub(:_set_default_designs)
      service.stub(:_set_default_addon_plans)
      site.stub(:loaders_updated_at=)
      site.stub(:settings_updated_at=)
      site.stub(:addons_updated_at=)
      site.stub(:save!)
    end

    it 'saves site twice' do
      site.should_receive(:save!).twice

      service.create.should be_true
    end

    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      site.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      service.create.should be_false
    end

    it 'creates a default kit' do
      service.should_receive(:_create_default_kit!)
      service.create.should be_true
    end

    it 'sets default app designs and add-ons to site after creation' do
      service.should_receive(:_set_default_designs)
      service.should_receive(:_set_default_addon_plans)

      service.create.should be_true
    end

    it 'touches loaders_updated_at & settings_updated_at' do
      site.should_receive(:loaders_updated_at=)
      site.should_receive(:settings_updated_at=)

      service.create.should be_true
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id)

      service.create.should be_true
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)

      service.create.should be_true
    end

    it 'delays the calculation of google and alexa ranks' do
      RankSetter.should delay(:set_ranks, queue: 'my-low').with(site.id)

      service.create.should be_true
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('sites.events', source: 'create')

      service.create.should be_true
    end
  end

  describe '#update' do
    let(:attributes) { { hostname: 'test.com' } }
    before do
      Site.stub(:transaction).and_yield
      site.stub(:attributes=)
      site.stub(:settings_updated_at=)
      site.stub(:save!)
    end

    it 'assignes attributes' do
      site.should_receive(:attributes=).with(attributes)

      service.update(attributes).should be_true
    end

    it 'saves site' do
      site.should_receive(:save!)

      service.update(attributes).should be_true
    end

    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      site.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      service.update(attributes).should be_false
    end

    it 'touches settings_updated_at' do
      site.should_receive(:settings_updated_at=)

      service.update(attributes).should be_true
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)

      service.update(attributes).should be_true
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'update')

      service.update(attributes).should be_true
    end
  end

  describe '#update_billable_items' do
    before do
      Site.stub(:transaction).and_yield
      service.stub(:_update_design_subscriptions)
      service.stub(:_update_addon_subscriptions)
      site.stub(:loaders_updated_at=)
      site.stub(:settings_updated_at=)
      site.stub(:addons_updated_at=)
      site.stub(:save!)
    end

    it 'sets designs billable items' do
      service.should_receive(:_update_design_subscriptions).with({ foo: '0' }, {})

      service.update_billable_items({ foo: '0' }, {})
    end

    it 'sets addon plans billable items' do
      service.should_receive(:_update_addon_subscriptions).with({ foo: '42' }, {})

      service.update_billable_items({}, { foo: '42' })
    end

    it 'saves site' do
      site.should_receive(:save!)

      service.update_billable_items({}, {})
    end

    it 'touches addons_updated_at' do
      site.should_receive(:addons_updated_at=)

      service.update_billable_items({}, {})
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id)

      service.update_billable_items({}, {})
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)

      service.update_billable_items({}, {})
    end
  end

end
