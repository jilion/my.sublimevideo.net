module RecurringJob

  logs_tasks = [
    '%Log::Voxcast%download_and_create_new_non_ssl_logs%',
    '%Log::Voxcast%download_and_create_new_ssl_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]

  NAMES = [
    '%RecurringJob%invoices_processing%',
    '%RecurringJob%sites_processing%',
    '%RecurringJob%users_processing%',
    '%Tweet%save_new_tweets_and_sync_favorite_tweets%',
    '%Stat%clear_old_seconds_minutes_and_hours_stats%',
    '%RecurringJob%stats_processing%'
  ] + logs_tasks

  class << self

    def delay_download_or_fetch_and_create_new_logs
      Log::Voxcast.download_and_create_new_logs
      Log::Amazon::S3::Player.delay_fetch_and_create_new_logs
      Log::Amazon::S3::Loaders.delay_fetch_and_create_new_logs
      Log::Amazon::S3::Licenses.delay_fetch_and_create_new_logs
    end

    def delay_invoices_processing
      unless Delayed::Job.already_delayed?('%RecurringJob%invoices_processing%')
        delay(priority: 2, run_at: Time.now.utc.tomorrow.midnight).invoices_processing
      end
    end

    def delay_sites_processing
      unless Delayed::Job.already_delayed?('%RecurringJob%sites_processing%')
        delay(priority: 3, run_at: Time.now.utc.tomorrow.midnight).sites_processing
      end
    end

    def delay_users_processing
      unless Delayed::Job.already_delayed?('%RecurringJob%users_processing%')
        delay(priority: 4, run_at: 1.week.from_now).users_processing
      end
    end

    def delay_stats_processing
      unless Delayed::Job.already_delayed?('%RecurringJob%stats_processing%')
        delay(priority: 5, run_at: Time.now.utc.tomorrow.midnight + 5.minutes).stats_processing
      end
    end

    def invoices_processing(priority=2)
      Invoice.delay(priority: priority).update_pending_dates_for_first_not_paid_invoices
      Site.delay(priority: priority).activate_or_downgrade_sites_leaving_trial
      Site.delay(priority: priority).renew_active_sites
      Transaction.delay(priority: priority).charge_invoices

      delay_invoices_processing
    end

    def sites_processing(priority=3)
      Site.delay(priority: priority).send_trial_will_expire
      Site.delay(priority: priority).monitor_sites_usages
      Site.delay(priority: priority).update_last_30_days_counters_for_not_archived_sites

      delay_sites_processing
    end

    def users_processing(priority=4)
      User.delay(priority: priority).send_credit_card_expiration

      delay_users_processing
    end

    def stats_processing(priority=5)
      %w[Users Sites Sales SiteStats SiteUsages Tweets].each do |stats_klass|
        "Stats::#{stats_klass}Stat".constantize.delay(priority: priority).create_stats
      end

      delay_stats_processing
    end

    def launch_all
      # Logs
      RecurringJob.delay_download_or_fetch_and_create_new_logs

      # Billing
      RecurringJob.delay_invoices_processing
      RecurringJob.delay_sites_processing
      RecurringJob.delay_users_processing

      # Others
      Tweet.delay_save_new_tweets_and_sync_favorite_tweets
      Stat.delay_clear_old_seconds_minutes_and_hours_stats

      # Stats
      RecurringJob.delay_stats_processing
    end

    def supervise
      # check if there is no too much delayed jobs
      max_jobs_allowed = 50
      if too_much_jobs?(max_jobs_allowed)
        Notify.send("WARNING!!! There is more than #{max_jobs_allowed} delayed jobs, please investigate quickly!")
      end
      # check if recurring jobs are all delayed
      if not_delayed.any?
        sleep 20
        if not_delayed.any?
          Notify.send("WARNING!!! The following jobs are not delayed: #{not_delayed.join(", ")}; please investigate quickly!")
        end
      end
    end

    def test_exception
      raise "THIS A DELAYED JOB EXCEPTION TEST"
    end

  private

    def not_delayed
      NAMES.reject { |name| Delayed::Job.already_delayed?(name) }
    end

    def too_much_jobs?(max)
      Delayed::Job.count > max
    end

  end
end
