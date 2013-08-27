require 'fast_spec_helper'
require 'timecop'
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
require 'scheduler'

Transaction = Class.new unless defined?(Transaction)
User = Class.new unless defined?(User)
Stats = Module.new unless defined?(Stats)
UsersTrend = Class.new unless defined?(UsersTrend)
SitesTrend = Class.new unless defined?(SitesTrend)
BillingsTrend = Class.new unless defined?(BillingsTrend)
RevenuesTrend = Class.new unless defined?(RevenuesTrend)
BillableItemsTrend = Class.new unless defined?(BillableItemsTrend)
SiteStatsTrend = Class.new unless defined?(SiteStatsTrend)
SiteUsagesTrend = Class.new unless defined?(SiteUsagesTrend)
TweetsTrend = Class.new unless defined?(TweetsTrend)
TailorMadePlayerRequestsTrend = Class.new unless defined?(TailorMadePlayerRequestsTrend)
Tweet = Class.new unless defined?(Tweet)
Log = Class.new unless defined?(Log)
Log::Voxcast = Class.new unless defined?(Log::Voxcast)

describe Scheduler do

  describe ".supervise_queues" do
    let(:sidekiq_queue) { double(Sidekiq::Queue) }
    before do
      Sidekiq::Client.stub(:registered_queues) { ['default'] }
      Sidekiq::Queue.stub(:new).with('default') { sidekiq_queue }
    end

    it "notifies if number of jobs is higher than threshold" do
      sidekiq_queue.should_receive(:size) { 100_001 }
      Notifier.should_receive(:send)
      described_class.supervise_queues
    end

    it "doesn't notify if number of jobs is low" do
      sidekiq_queue.should_receive(:size) { 99_999 }
      Notifier.should_not_receive(:send)
      described_class.supervise_queues
    end
  end

  describe ".schedule_daily_tasks" do
    it "schedules InvoiceCreator.create_invoices_for_month" do
      InvoiceCreator.should delay(:create_invoices_for_month,
        at: (Time.now.utc.tomorrow.midnight + 30.minutes).to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.send_trial_will_expire_emails" do
      TrialHandler.should delay(:send_trial_will_expire_emails,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.activate_billable_items_out_of_trial" do
      TrialHandler.should delay(:activate_billable_items_out_of_trial,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteCountersUpdater.set_first_billable_plays_at_for_not_archived_sites" do
      SiteCountersUpdater.should delay(:set_first_billable_plays_at_for_not_archived_sites,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteCountersUpdater.update_last_30_days_counters_for_not_archived_sites" do
      SiteCountersUpdater.should delay(:update_last_30_days_counters_for_not_archived_sites,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Transaction.charge_invoices" do
      Transaction.should delay(:charge_invoices,
        at: (Time.now.utc.tomorrow.midnight + 6.hours).to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules User.send_emails" do
      CreditCardExpirationNotifier.should delay(:send_emails,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules NewInactiveUserNotifier.send_emails" do
      NewInactiveUserNotifier.should delay(:send_emails,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules UsersTrend.create_trends" do
      UsersTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SitesTrend.create_trends" do
      SitesTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      BillingsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules RevenuesTrend.create_trends" do
      RevenuesTrend.should delay(:create_trends,
        at: (Time.now.utc.tomorrow.midnight + 3.hours).to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      BillableItemsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteStatsTrend.create_trends" do
      SiteStatsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteUsagesTrend.create_trends" do
      SiteUsagesTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TweetsTrend.create_trends" do
      TweetsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TailorMadePlayerRequestsTrend.create_trends" do
      TailorMadePlayerRequestsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'low'
      )
      described_class.schedule_daily_tasks
    end
  end

  describe ".schedule_hourly_tasks" do
    it "schedules Tweet.save_new_tweets_and_sync_favorite_tweets" do
      Tweet.should delay(:save_new_tweets_and_sync_favorite_tweets,
        at:    1.hour.from_now.change(min: 0).to_i,
        queue: 'low'
      )
      described_class.schedule_hourly_tasks
    end
  end

  describe ".schedule_frequent_tasks" do
    it "schedules 10 times Log::Voxcast.delay_download_and_create_new_logs" do
      Timecop.freeze do
        10.times do |i|
          Log::Voxcast.should delay(:download_and_create_new_logs,
            queue: 'high',
            at:    (i + 1).minutes.from_now.change(sec: 0).to_i + 5
          )
        end

        described_class.schedule_frequent_tasks
      end
    end
  end
end
