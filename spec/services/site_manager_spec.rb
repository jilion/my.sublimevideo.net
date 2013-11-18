require 'fast_spec_helper'
require 'rails/railtie'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'models/app'
require 'services/site_manager'

Site = Struct.new(:params) unless defined?(Site)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new(Exception) unless defined?(ActiveRecord::RecordInvalid)

describe SiteManager do
  let(:user)    { double(sites: []) }
  let(:site)    { Struct.new(:user, :id, :hostname, :dev_hostnames).new(nil, 1234, nil, nil) }
  let(:service) { described_class.new(site) }

  before do
    Site.stub(:transaction).and_yield
    site.stub(:save!)
    service.stub(:_create_default_kit!)
    service.stub(:_set_default_billable_items)
    Librato.stub(:increment)
  end

  describe '#create' do
    let(:addons_subscriber) { double('AddonsSubscriber') }
    before do
      service.stub(:touch_timestamps)
      service.stub(:delay_jobs)
      AddonsSubscriber.should_receive(:new).with(site).and_return(addons_subscriber)
      addons_subscriber.stub(:update_billable_items)
    end

    it 'saves site twice' do
      site.should_receive(:save!).twice

      service.create.should be_true
    end

    it 'sets hostname to DEFAULT_DOMAIN if hostname is blank?' do
      allow_message_expectations_on_nil
      site.hostname.stub(:blank?).and_return(true)
      site.should_receive(:hostname=).with(described_class::DEFAULT_DOMAIN)

      service.create.should be_true
    end

    it 'sets dev_hostnames to DEFAULT_DEV_DOMAINS if dev_hostnames are blank?' do
      allow_message_expectations_on_nil
      site.dev_hostnames.stub(:blank?).and_return(true)
      site.should_receive(:dev_hostnames=).with(described_class::DEFAULT_DEV_DOMAINS)

      service.create.should be_true
    end

    # Fails when the real ActiveRecord::RecordInvalid class is defined... (for instance when running the full suite)
    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      site.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      service.create.should be_false
    end

    it 'creates a default kit' do
      service.should_receive(:_create_default_kit!)
      service.create.should be_true
    end

    it 'sets default app designs and add-ons to site after creation' do
      service.should_receive(:_set_default_billable_items)

      service.create.should be_true
    end

    it 'touches loaders_updated_at & settings_updated_at' do
      service.should_receive(:touch_timestamps).with(%w[loaders settings])

      service.create.should be_true
    end

    it 'delays the update of the site rankings' do
      service.should_receive(:delay_jobs).with(:rank_update)

      service.create.should be_true
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'create')

      service.create.should be_true
    end
  end

  describe '#update' do
    let(:attributes) { { hostname: 'test.com' } }
    before do
      service.stub(:touch_timestamps)
      service.stub(:delay_jobs)
      site.stub(:attributes=)
    end

    it 'assignes attributes' do
      site.should_receive(:attributes=).with(attributes)

      service.update(attributes).should be_true
    end

    it 'saves site' do
      site.should_receive(:save!)

      service.update(attributes).should be_true
    end

    # Fails when the real ActiveRecord::RecordInvalid class is defined... (for instance when running the full suite)
    pending 'returns false if a ActiveRecord::RecordInvalid is raised' do
      site.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      service.update(attributes).should be_false
    end

    it 'touches settings_updated_at' do
      service.should_receive(:touch_timestamps).with('settings')

      service.update(attributes).should be_true
    end

    it 'delays the update of all settings types' do
      service.should_receive(:delay_jobs).with(:settings_update)

      service.update(attributes).should be_true
    end

    it 'increments metrics' do
      Librato.should_receive(:increment).with('sites.events', source: 'update')

      service.update(attributes).should be_true
    end
  end

  describe '#touch_timestamps' do
    context 'single timestamps' do
      it 'touches appropriate timestamp' do
        site.should_receive(:loaders_updated_at=)

        service.touch_timestamps('loaders').should be_true
      end
    end

    context 'multiple timestamps' do
      it 'touches appropriate timestamps' do
        site.should_receive(:loaders_updated_at=)
        site.should_receive(:settings_updated_at=)
        site.should_receive(:addons_updated_at=)

        service.touch_timestamps(%w[loaders settings addons]).should be_true
      end
    end
  end

  describe '#delay_jobs' do
    context 'single job' do
      it 'delays the right job' do
        LoaderGenerator.should delay(:update_all_stages!).with(site.id)

        service.delay_jobs(:loader_update)
      end
    end

    context 'multiple jobs' do
      it 'delays the right jobs' do
        LoaderGenerator.should delay(:update_all_stages!).with(site.id)
        SettingsGenerator.should delay(:update_all!).with(site.id)
        RankSetter.should delay(:set_ranks, queue: 'my-low').with(site.id)

        service.delay_jobs(:loader_update, :settings_update, :rank_update)
      end
    end
  end

end
