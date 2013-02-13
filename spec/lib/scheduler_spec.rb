require 'fast_spec_helper'
require 'active_support/core_ext'
require 'sidekiq'
require 'config/sidekiq'
require 'support/sidekiq_custom_matchers'

require 'services/notifier'
require 'services/site_manager'
require 'services/trial_handler'
require 'services/invoice_creator'
require 'services/site_counters_updater'
require 'services/credit_card_expiration_notifier'
require 'services/new_inactive_user_notifier'
require 'scheduler'

unless defined?(ActiveRecord)
  Transaction = Class.new
  User = Class.new
  Stats = Class.new
  Stats::UsersStat = Class.new
  Stats::SitesStat = Class.new
  Stats::BillingsStat = Class.new
  Stats::RevenuesStat = Class.new
  Stats::BillableItemsStat = Class.new
  Stats::SiteStatsStat = Class.new
  Stats::SiteUsagesStat = Class.new
  Stats::TweetsStat = Class.new
  Stats::TailorMadePlayerRequestsStat = Class.new
  Tweet = Class.new
  Log = Class.new
  Log::Amazon = Class.new
  Log::Voxcast = Class.new
  Log::Amazon::S3 = Class.new
  Log::Amazon::S3::Player = Class.new
  Log::Amazon::S3::Loaders = Class.new
  Log::Amazon::S3::Licenses = Class.new
end

describe Scheduler do

  describe ".supervise_queues" do
    let(:sidekiq_queue) { mock(Sidekiq::Queue) }
    before do
      Sidekiq::Client.stub(:registered_queues) { ['default'] }
      Sidekiq::Queue.stub(:new).with('default') { sidekiq_queue }
    end

    it "notifies if number of jobs is higher than threshold" do
      sidekiq_queue.should_receive(:size) { 10001 }
      Notifier.should_receive(:send)
      described_class.supervise_queues
    end

    it "doesn't notify if number of jobs is low" do
      sidekiq_queue.should_receive(:size) { 9999 }
      Notifier.should_not_receive(:send)
      described_class.supervise_queues
    end
  end

  describe ".schedule_daily_tasks" do
    it "schedules InvoiceCreator.create_invoices_for_month" do
      InvoiceCreator.should delay(:create_invoices_for_month,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.send_trial_will_expire_email" do
      TrialHandler.should delay(:send_trial_will_expire_email,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TrialHandler.activate_billable_items_out_of_trial!" do
      TrialHandler.should delay(:activate_billable_items_out_of_trial!,
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
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules NewInactiveUserNotifier.send_emails" do
      NewInactiveUserNotifier.should delay(:send_emails,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::UsersStat.create_stats" do
      Stats::UsersStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::SitesStat.create_stats" do
      Stats::SitesStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::BillingsStat.create_stats" do
      Stats::BillingsStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::RevenuesStat.create_stats" do
      Stats::RevenuesStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::BillingsStat.create_stats" do
      Stats::BillableItemsStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::SiteStatsStat.create_stats" do
      Stats::SiteStatsStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::SiteUsagesStat.create_stats" do
      Stats::SiteUsagesStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::TweetsStat.create_stats" do
      Stats::TweetsStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Stats::TailorMadePlayerRequestsStat.create_stats" do
      Stats::TailorMadePlayerRequestsStat.should delay(:create_stats,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end
  end

  describe ".schedule_hourly_tasks" do
    it "schedules Tweet.save_new_tweets_and_sync_favorite_tweets" do
      Tweet.should delay(:save_new_tweets_and_sync_favorite_tweets,
        at:    1.hour.from_now.change(min: 0).to_i,
        queue: "low"
      )
      described_class.schedule_hourly_tasks
    end

    it "schedules Log::Amazon::S3::Player.fetch_and_create_new_logs" do
      Log::Amazon::S3::Player.should delay(:fetch_and_create_new_logs,
        at:    1.hour.from_now.change(min: 0).to_i,
        queue: "low"
      )
      described_class.schedule_hourly_tasks
    end

    it "schedules Log::Amazon::S3::Loaders.fetch_and_create_new_logs" do
      Log::Amazon::S3::Loaders.should delay(:fetch_and_create_new_logs,
        at:    1.hour.from_now.change(min: 0).to_i,
        queue: "low"
      )
      described_class.schedule_hourly_tasks
    end

    it "schedules Log::Amazon::S3::Licenses.fetch_and_create_new_logs" do
      Log::Amazon::S3::Licenses.should delay(:fetch_and_create_new_logs,
        at:    1.hour.from_now.change(min: 0).to_i,
        queue: "low"
      )
      described_class.schedule_hourly_tasks
    end
  end

  describe ".schedule_frequent_tasks" do
    it "schedules 10 times Log::Voxcast.delay_download_and_create_new_logs" do
      10.times do |i|
        Log::Voxcast.should delay(:download_and_create_new_logs,
          queue: "high",
          at:    (i + 1).minutes.from_now.change(sec: 0).to_i + 5
        )
      end

      described_class.schedule_frequent_tasks
    end
  end
end
