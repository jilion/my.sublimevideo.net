require 'fast_spec_helper'
require 'active_support/core_ext'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/notifier'
require 'services/site_manager'
require 'services/trial_handler'
require 'services/invoice_creator'
require 'services/site_counters_updater'
require 'services/credit_card_expiration_notifier'
require 'services/new_inactive_user_notifier'
require 'workers/tweets_saver_worker'
require 'workers/tweets_syncer_worker'
require 'scheduler'

Transaction = Class.new unless defined?(Transaction)
User = Class.new unless defined?(User)
Stats = Module.new unless defined?(Stats)
UsersTrend = Class.new unless defined?(UsersTrend)
SitesTrend = Class.new unless defined?(SitesTrend)
BillingsTrend = Class.new unless defined?(BillingsTrend)
RevenuesTrend = Class.new unless defined?(RevenuesTrend)
BillableItemsTrend = Class.new unless defined?(BillableItemsTrend)
SiteAdminStatsTrend = Class.new unless defined?(SiteAdminStatsTrend)
TweetsTrend = Class.new unless defined?(TweetsTrend)
TailorMadePlayerRequestsTrend = Class.new unless defined?(TailorMadePlayerRequestsTrend)
Tweet = Class.new unless defined?(Tweet)
Tweet::KEYWORDS = ['rymai'] unless defined?(Tweet::KEYWORDS)

describe Scheduler do

  describe ".supervise_queues" do
    let(:sidekiq_queue) { double(Sidekiq::Queue) }
    before do
      allow(Sidekiq::Client).to receive(:registered_queues) { ['default'] }
      allow(Sidekiq::Queue).to receive(:new).with('default') { sidekiq_queue }
    end

    it "notifies if number of jobs is higher than threshold" do
      expect(sidekiq_queue).to receive(:size) { 100_001 }
      expect(Notifier).to receive(:send)
      described_class.supervise_queues
    end

    it "doesn't notify if number of jobs is low" do
      expect(sidekiq_queue).to receive(:size) { 99_999 }
      expect(Notifier).not_to receive(:send)
      described_class.supervise_queues
    end
  end

  describe ".schedule_daily_tasks" do
    it "schedules InvoiceCreator.create_invoices_for_month" do
      expect(InvoiceCreator).to delay(:create_invoices_for_month,
        queue: 'my',
        at: (Time.now.utc.tomorrow.midnight + 30.minutes).to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.send_trial_will_expire_emails" do
      expect(TrialHandler).to delay(:send_trial_will_expire_emails,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.activate_billable_items_out_of_trial" do
      expect(TrialHandler).to delay(:activate_billable_items_out_of_trial,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteCountersUpdater.update_not_archived_sites" do
      expect(SiteCountersUpdater).to delay(:update_not_archived_sites,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Transaction.charge_invoices" do
      expect(Transaction).to delay(:charge_invoices,
        queue: 'my',
        at: (Time.now.utc.tomorrow.midnight + 6.hours).to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules User.send_emails" do
      expect(CreditCardExpirationNotifier).to delay(:send_emails,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules NewInactiveUserNotifier.send_emails" do
      expect(NewInactiveUserNotifier).to delay(:send_emails,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules UsersTrend.create_trends" do
      expect(UsersTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SitesTrend.create_trends" do
      expect(SitesTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      expect(BillingsTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules RevenuesTrend.create_trends" do
      expect(RevenuesTrend).to delay(:create_trends,
        at: (Time.now.utc.tomorrow.midnight + 3.hours).to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      expect(BillableItemsTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteAdminStatsTrend.create_trends" do
      expect(SiteAdminStatsTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TweetsTrend.create_trends" do
      expect(TweetsTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TailorMadePlayerRequestsTrend.create_trends" do
      expect(TailorMadePlayerRequestsTrend).to delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end
  end

  describe ".schedule_hourly_tasks" do
    it "schedules TweetsSaverWorker.perform_async" do
      Tweet::KEYWORDS.each { |k| expect(TweetsSaverWorker).to receive(:perform_async).with(k) }
      described_class.schedule_hourly_tasks
    end
    it "schedules TweetsSyncerWorker.perform_async" do
      expect(TweetsSyncerWorker).to receive(:perform_in)
      described_class.schedule_hourly_tasks
    end
  end
end
