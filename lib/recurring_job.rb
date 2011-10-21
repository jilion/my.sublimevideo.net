module RecurringJob

  logs_tasks = [
    '%Log::Voxcast%download_and_create_new_non_ssl_logs%',
    '%Log::Voxcast%download_and_create_new_ssl_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]

  stats_tasks = [
    '%UsersStat%create_users_stats%',
    '%SitesStat%create_sites_stats%'
  ]

  NAMES = [
    '%User::CreditCard%send_credit_card_expiration%',
    '%RecurringJob%invoices_processing%',
    '%Site::UsageMonitoring%monitor_sites_usages%',
    '%Site%update_last_30_days_counters_for_not_archived_sites%',
    '%Tweet%save_new_tweets_and_sync_favorite_tweets%',
    '%SiteStat%clear_old_seconds_minutes_and_days_stats%'
  ] + logs_tasks + stats_tasks

  class << self

    def delay_invoices_processing
      unless Delayed::Job.already_delayed?('%RecurringJob%invoices_processing%')
        delay(:priority => 2, :run_at => Time.now.utc.tomorrow.midnight).invoices_processing
      end
    end

    def invoices_processing
      Invoice.update_pending_dates_for_first_not_paid_invoices
      Site.renew_active_sites
      Transaction.charge_invoices
      delay_invoices_processing
    end

    def launch_all
      # Logs
      Log.delay_download_or_fetch_and_create_new_logs

      # Stats
      UsersStat.delay_create_users_stats
      SitesStat.delay_create_sites_stats

      # Billing
      RecurringJob.delay_invoices_processing

      # Others
      User::CreditCard.delay_send_credit_card_expiration
      Site::UsageMonitoring.delay_monitor_sites_usages
      Site.delay_update_last_30_days_counters_for_not_archived_sites
      Tweet.delay_save_new_tweets_and_sync_favorite_tweets
      SiteStat.delay_clear_old_seconds_minutes_and_days_stats
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
