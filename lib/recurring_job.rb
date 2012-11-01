require_dependency 'notify'
require_dependency 'service/site'
require_dependency 'service/trial'
require_dependency 'service/invoice'
require_dependency 'service/usage'

module RecurringJob
  class << self

    def supervise_queues(jobs_threshold = 100)
      jobs_count = Sidekiq.options[:queues].sum do |queue|
        Sidekiq::Queue.new(queue).size
      end

      if jobs_count > jobs_threshold
        Notify.send("WARNING!!! There is more than #{jobs_threshold} jobs in queues, please investigate quickly!")
      end
    end

    def schedule_daily_tasks
      options = {
        at: (Time.now.utc.tomorrow.midnight + 5.minutes).to_i,
      }

      Service::Invoice.delay(options).create_invoices_for_month
      Transaction.delay(options).charge_invoices
      Service::Trial.delay(options).send_trial_will_expire_email
      Service::Trial.delay(options).activate_billable_items_out_of_trial!
      Service::Usage.delay(options).set_first_billable_plays_at_for_not_archived_sites
      Service::Usage.delay(options).update_last_30_days_counters_for_not_archived_sites

      options.merge!(queue: 'low')

      User.delay(options).send_credit_card_expiration
      User.delay(options).send_inactive_account_email
      Stats::UsersStat.delay(options).create_stats
      Stats::SitesStat.delay(options).create_stats
      Stats::SalesStat.delay(options).create_stats
      Stats::SiteStatsStat.delay(options).create_stats
      Stats::SiteUsagesStat.delay(options).create_stats
      Stats::TweetsStat.delay(options).create_stats
    end

    def schedule_hourly_tasks
      options = {
        at: 1.hour.from_now.change(min: 0).to_i,
        queue: 'low'
      }

      Tweet.delay(options).save_new_tweets_and_sync_favorite_tweets
      Log::Amazon::S3::Player.delay(options).fetch_and_create_new_logs
      Log::Amazon::S3::Loaders.delay(options).fetch_and_create_new_logs
      Log::Amazon::S3::Licenses.delay(options).fetch_and_create_new_logs
    end

    def schedule_frequent_tasks
      options = { queue: 'high' }

      10.times do |i|
        options[:at] = (i + 1).minutes.from_now.change(sec: 0).to_i
        Log::Voxcast.delay_download_and_create_new_logs(options)
      end
    end

  end
end
