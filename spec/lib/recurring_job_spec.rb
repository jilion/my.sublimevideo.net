require 'fast_spec_helper'
require 'sidekiq'
require File.expand_path('config/initializers/sidekiq')

require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/recurring_job')

unless defined?(ActiveRecord)
  Transaction = Class.new
  User = Class.new
  Stats = Class.new
  Stats::UsersStat = Class.new
  Stats::SitesStat = Class.new
  Stats::BillingsStat = Class.new
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

describe RecurringJob do

  describe ".supervise_queues" do
    let(:sidekiq_queue) { mock(Sidekiq::Queue) }
    before do
      Sidekiq::Client.stub(:registered_queues) { ['default'] }
      Sidekiq::Queue.stub(:new).with('default') { sidekiq_queue }
    end

    it "notifies if number of jobs is higher than threshold" do
      sidekiq_queue.should_receive(:size) { 10001 }
      Notify.should_receive(:send)
      described_class.supervise_queues
    end

    it "doesn't notify if number of jobs is low" do
      sidekiq_queue.should_receive(:size) { 9999 }
      Notify.should_not_receive(:send)
      described_class.supervise_queues
    end
  end

  describe ".schedule_daily_tasks" do
    it "schedules Service::Invoice.create_invoices_for_month" do
      Service::Invoice.should delay(:create_invoices_for_month,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Service::Trial.send_trial_will_expire_email" do
      Service::Trial.should delay(:send_trial_will_expire_email,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Service::Trial.activate_billable_items_out_of_trial!" do
      Service::Trial.should delay(:activate_billable_items_out_of_trial!,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Service::Usage.set_first_billable_plays_at_for_not_archived_sites" do
      Service::Usage.should delay(:set_first_billable_plays_at_for_not_archived_sites,
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules Service::Usage.update_last_30_days_counters_for_not_archived_sites" do
      Service::Usage.should delay(:update_last_30_days_counters_for_not_archived_sites,
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

    it "schedules User.send_credit_card_expiration_email" do
      Service::CreditCard.should delay(:send_credit_card_expiration_email,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: "low"
      )
      described_class.schedule_daily_tasks
    end

    it "schedules User.send_inactive_account_email" do
      User.should delay(:send_inactive_account_email,
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
