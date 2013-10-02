module Scheduler
  def self.supervise_queues(jobs_threshold = 100_000)
    queues = Sidekiq::Client.registered_queues
    jobs_count = queues.sum do |queue|
      Sidekiq::Queue.new(queue).size
    end

    if jobs_count > jobs_threshold
      Notifier.send("WARNING!!! There is more than #{jobs_threshold} jobs in queues, please investigate quickly!")
    end
  end

  def self.schedule_daily_tasks
    schedule_daily_light_tasks
    schedule_daily_heavy_tasks
  end

  def self.schedule_daily_light_tasks
    options = { queue: 'my-low', at: Time.now.utc.tomorrow.midnight.to_i }

    TrialHandler.delay(options).send_trial_will_expire_emails
    TrialHandler.delay(options).activate_billable_items_out_of_trial
    SiteCountersUpdater.delay(options).update_not_archived_sites
    CreditCardExpirationNotifier.delay(options).send_emails
    NewInactiveUserNotifier.delay(options).send_emails
    UsersTrend.delay(options).create_trends
    SitesTrend.delay(options).create_trends
    BillingsTrend.delay(options).create_trends
    BillableItemsTrend.delay(options).create_trends
    SiteStatsTrend.delay(options).create_trends
    TweetsTrend.delay(options).create_trends
    TailorMadePlayerRequestsTrend.delay(options).create_trends
  end

  def self.schedule_daily_heavy_tasks
    InvoiceCreator.delay(queue: 'my', at: (Time.now.utc.tomorrow.midnight + 30.minutes).to_i).create_invoices_for_month
    RevenuesTrend.delay(queue: 'my-low', at: (Time.now.utc.tomorrow.midnight + 3.hours).to_i).create_trends
    Transaction.delay(queue: 'my', at: (Time.now.utc.tomorrow.midnight + 6.hours).to_i).charge_invoices
  end

  def self.schedule_hourly_tasks
    Tweet::KEYWORDS.each { |keyword| TweetsSaverWorker.perform_async(keyword) }
    TweetsSyncerWorker.perform_in(5.minutes.from_now)
  end

end
