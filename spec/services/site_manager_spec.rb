require 'fast_spec_helper'
require 'support/matchers/sidekiq_matchers'

require 'services/site_manager'

Site = Struct.new(:params) unless defined?(Site)
AddonPlan = Class.new unless defined?(AddonPlan)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new unless defined?(ActiveRecord::RecordInvalid)

describe SiteManager do
  let(:user)    { stub(sites: [], early_access?: true) }
  let(:site)    { Struct.new(:user, :id, :token).new(user, 1234, 'abcd1234') }
  let(:service) { described_class.new(site) }

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
      service.create
    end

    it 'creates a default kit' do
      service.should_receive(:_create_default_kit!)
      service.create
    end

    it 'sets default app designs and add-ons to site after creation' do
      service.should_receive(:_set_default_designs)
      service.should_receive(:_set_default_addon_plans)
      service.create
    end

    it 'touches loaders_updated_at & settings_updated_at' do
      site.should_receive(:loaders_updated_at=)
      site.should_receive(:settings_updated_at=)
      service.create
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id)
      service.create
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)
      service.create
    end

    it 'delays the calculation of google and alexa ranks' do
      RankSetter.should delay(:set_ranks, queue: 'low').with(site.id)
      service.create
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('sites.events', source: 'create')
      service.create
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
      SettingsGenerator.should delay(:update_all!).with(site.id)
      service.update(attributes)
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('sites.events', source: 'update')
      service.update(attributes)
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

  describe '#suspend' do
    before do
      Site.stub(:transaction).and_yield
      service.stub(:_suspend_billable_items!)
      site.stub(:suspend!)
    end

    it 'suspends the site' do
      site.should_receive(:suspend!)
      service.suspend
    end

    it 'suspends all billable items' do
      service.should_receive(:_suspend_billable_items!)
      service.suspend
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id, deletable: true)
      service.suspend
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)
      service.suspend
    end

    it 'delays the update of the player files (if user has early access)' do
      PlayerFilesGeneratorWorker.should_receive(:perform_async).with(site.token, :cancellation)
      service.suspend
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'suspend')
      service.suspend
    end
  end

  describe '#unsuspend!' do
    before do
      Site.stub(:transaction).and_yield
      service.stub(:_unsuspend_billable_items!)
      site.stub(:unsuspend!)
    end

    it 'unsuspends the site' do
      site.should_receive(:unsuspend!)
      service.unsuspend
    end

    it 'unsuspends all billable items' do
      service.should_receive(:_unsuspend_billable_items!)
      service.unsuspend
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id)
      service.unsuspend
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)
      service.unsuspend
    end

    it 'delays the update of the player files (if user has early access)' do
      PlayerFilesGeneratorWorker.should_receive(:perform_async).with(site.token, :settings_update).ordered
      PlayerFilesGeneratorWorker.should_receive(:perform_async).with(site.token, :addons_update).ordered
      service.unsuspend
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'unsuspend')
      service.unsuspend
    end
  end

  describe '#archive' do
    before do
      Site.stub(:transaction).and_yield
      service.stub(:_cancel_billable_items)
      site.stub(:archived_at=)
      site.stub(:archive!)
    end

    it 'touches addons_updated_at' do
      site.should_receive(:archived_at=)
      service.archive
    end

    it 'archives the site' do
      site.should_receive(:archive!)
      service.archive
    end

    it 'clears all billable items' do
      service.should_receive(:_cancel_billable_items)
      service.archive
    end

    it 'delays the update of all loader stages' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id, deletable: true)
      service.archive
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(site.id)
      service.archive
    end

    it 'delays the update of the player files (if user has early access)' do
      PlayerFilesGeneratorWorker.should_receive(:perform_async).with(site.token, :cancellation)
      service.archive
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'archive')
      service.archive
    end
  end

end
