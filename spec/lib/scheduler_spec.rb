require 'fast_spec_helper'
require 'active_support/core_ext'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/notifier'
require 'services/site_manager'
require 'services/site_counters_updater'
require 'workers/tweets_saver_worker'
require 'workers/tweets_syncer_worker'
require 'scheduler'

User = Class.new unless defined?(User)
Stats = Module.new unless defined?(Stats)
UsersTrend = Class.new unless defined?(UsersTrend)
SitesTrend = Class.new unless defined?(SitesTrend)
BillingsTrend = Class.new unless defined?(BillingsTrend)
BillableItemsTrend = Class.new unless defined?(BillableItemsTrend)
SiteAdminStatsTrend = Class.new unless defined?(SiteAdminStatsTrend)
TweetsTrend = Class.new unless defined?(TweetsTrend)
Tweet = Class.new unless defined?(Tweet)
Tweet::KEYWORDS = ['rymai'] unless defined?(Tweet::KEYWORDS)

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
    it "schedules SiteCountersUpdater.update_not_archived_sites" do
      SiteCountersUpdater.should delay(:update_not_archived_sites,
        queue: 'my-low',
        at: Time.now.utc.tomorrow.midnight.to_i
      )
      described_class.schedule_daily_tasks
    end

    it "schedules UsersTrend.create_trends" do
      UsersTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SitesTrend.create_trends" do
      SitesTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      BillingsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules BillingsTrend.create_trends" do
      BillableItemsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules SiteAdminStatsTrend.create_trends" do
      SiteAdminStatsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end

    it "schedules TweetsTrend.create_trends" do
      TweetsTrend.should delay(:create_trends,
        at: Time.now.utc.tomorrow.midnight.to_i,
        queue: 'my-low'
      )
      described_class.schedule_daily_tasks
    end
  end

  describe ".schedule_hourly_tasks" do
    it "schedules TweetsSaverWorker.perform_async" do
      Tweet::KEYWORDS.each { |k| TweetsSaverWorker.should receive(:perform_async).with(k) }
      described_class.schedule_hourly_tasks
    end
    it "schedules TweetsSyncerWorker.perform_async" do
      TweetsSyncerWorker.should receive(:perform_in)
      described_class.schedule_hourly_tasks
    end
  end
end
