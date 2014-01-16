require 'fast_spec_helper'
require 'rails/railtie'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/addons_subscriber'

Site = Struct.new(:params) unless defined?(Site)
# AddonPlan = Class.new unless defined?(AddonPlan)

describe AddonsSubscriber do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:service) { described_class.new(site) }

  before do
    Librato.stub(:increment)
    SiteManager.any_instance.stub(:transaction_with_graceful_fail).and_yield
  end

  describe '.subscribe_site_to_addon' do
    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      Site.should_receive(:find) { site }
      described_class.should_receive(:new).with(site) do |service|
        service.should_receive(:update_billable_items).with({}, { 'embed' => 42 })
        service
      end

      described_class.subscribe_site_to_addon(site.id, 'embed', 42)
    end
  end

  describe '.update_billable_items' do
    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      Site.should_receive(:find) { site }
      described_class.should_receive(:new).with(site) do |service|
        service.should_receive(:update_billable_items).with({ 'classic' => 12 }, { 'embed' => 42 }, {})
        service
      end

      described_class.update_billable_items(site.id, { 'classic' => 12 }, { 'embed' => 42 })
    end
  end

  describe '#update_billable_items' do
    let(:site_manager) { double('SiteManager') }
    before do
      service.stub(:_update_design_subscriptions)
      service.stub(:_update_addon_subscriptions)
      site.stub(:save!)

      SiteManager.should_receive(:new).with(site).and_return(site_manager)
      site_manager.stub(:transaction_with_graceful_fail).and_yield
      site_manager.stub(:touch_timestamps)
      site_manager.stub(:delay_jobs)
    end

    it 'asks the site manager to wrap the changes in a transaction' do
      site_manager.should_receive(:transaction_with_graceful_fail)

      service.update_billable_items({ foo: '0' }, {})
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

    it 'asks the site manager to touch its timestamps' do
      site_manager.should_receive(:touch_timestamps).with(%w[loaders settings addons])

      service.update_billable_items({}, {})
    end

    it 'asks the site manager to delay its jobs' do
      site_manager.should_receive(:delay_jobs)

      service.update_billable_items({}, {})
    end
  end

  describe '#suspend_billable_items' do
    before do
      site.stub(billable_items: [double, double])
    end

    it 'calls #suspend! on each billable item' do
      site.billable_items.each { |bi| bi.should_receive(:suspend!) }

      service.suspend_billable_items
    end
  end

  describe '#unsuspend_billable_items' do
    before do
      site.stub(billable_items: double)
    end

    it 'update the state of each billable item' do
      suspended_billable_items = [double, double]
      site.billable_items.should_receive(:where).with(state: 'suspended').and_return(suspended_billable_items)
      suspended_billable_items.each { |bi| service.should_receive(:_update_billable_item_state!).with(bi) }

      service.unsuspend_billable_items
    end
  end

  describe '#cancel_billable_items' do
    before do
      site.stub(billable_items: double)
    end

    it 'calls #destroy_all on the billable item association' do
      site.billable_items.should_receive(:destroy_all)

      service.cancel_billable_items
    end
  end

  describe '#_update_design_subscriptions' do
    let(:design_subscriptions) { { 'classic' => 12, 'light' => 42 } }

    it 'delegates to #_update_design_subscription for each design subscription' do
      design_subscriptions.each do |design_name, design_id|
        service.should_receive(:_update_design_subscription).with(design_name, design_id, foo: 'bar')
      end

      service.send :_update_design_subscriptions, design_subscriptions, foo: 'bar'
    end
  end

  describe '#_update_addon_subscriptions' do
    let(:addon_subscriptions) { { 'embed' => 12, 'stats' => 42 } }

    it 'delegates to #_update_addon_plan_subscription for each design subscription' do
      addon_subscriptions.each do |addon_name, addon_plan_id|
        service.should_receive(:_update_addon_subscription).with(addon_name, addon_plan_id, foo: 'bar')
      end

      service.send :_update_addon_subscriptions, addon_subscriptions, foo: 'bar'
    end
  end

end
