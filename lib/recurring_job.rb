module RecurringJob

  LOGS_TASKS = [
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
    '%RecurringJob%tweets_processing%',
    '%Stat%clear_old_seconds_minutes_and_hours_stats%',
    '%RecurringJob%stats_processing%'
  ] + LOGS_TASKS

  PRIORITIES = {
    logs:     1,
    invoices: 2,
    sites:    3,
    users:    4,
    tweets:   5,
    stats:    6
  }

  class << self

    def delay_download_or_fetch_and_create_new_logs
      Log::Voxcast.download_and_create_new_logs
      Log::Amazon::S3::Player.delay_fetch_and_create_new_logs
      Log::Amazon::S3::Loaders.delay_fetch_and_create_new_logs
      Log::Amazon::S3::Licenses.delay_fetch_and_create_new_logs
    end

    def delay_invoices_processing(priority=PRIORITIES[:invoices])
      unless Delayed::Job.already_delayed?('%RecurringJob%invoices_processing%')
        delay(priority: priority, run_at: Time.now.utc.tomorrow.midnight).invoices_processing(priority)
      end
    end

    def delay_sites_processing(priority=PRIORITIES[:sites])
      unless Delayed::Job.already_delayed?('%RecurringJob%sites_processing%')
        delay(priority: priority, run_at: Time.now.utc.tomorrow.midnight).sites_processing(priority)
      end
    end

    def delay_users_processing(priority=PRIORITIES[:users])
      unless Delayed::Job.already_delayed?('%RecurringJob%users_processing%')
        delay(priority: priority, run_at: 1.week.from_now).users_processing(priority)
      end
    end

    def delay_tweets_processing(priority=PRIORITIES[:tweets])
      unless Delayed::Job.already_delayed?('%RecurringJob%tweets_processing%')
        delay(priority: priority, run_at: 45.minutes.from_now).tweets_processing(priority)
      end
    end

    def delay_stats_processing(priority=PRIORITIES[:stats])
      unless Delayed::Job.already_delayed?('%RecurringJob%stats_processing%')
        delay(priority: priority, run_at: Time.now.utc.tomorrow.midnight + 5.minutes).stats_processing(priority)
      end
    end

    def invoices_processing(priority=PRIORITIES[:invoices])
      Invoice.delay(priority: priority).update_pending_dates_for_first_not_paid_invoices
      Site.delay(priority: priority).activate_or_downgrade_sites_leaving_trial
      Site.delay(priority: priority).renew_active_sites
      Transaction.delay(priority: priority + 1, run_at: 5.minutes.from_now).charge_invoices

      delay_invoices_processing
    end

    def sites_processing(priority=PRIORITIES[:sites])
      Site.delay(priority: priority).send_trial_will_expire
      Site.delay(priority: priority).monitor_sites_usages
      Site.delay(priority: priority).update_last_30_days_counters_for_not_archived_sites

      delay_sites_processing
    end

    def users_processing(priority=PRIORITIES[:users])
      User.delay(priority: priority).send_credit_card_expiration

      delay_users_processing
    end

    def tweets_processing(priority=PRIORITIES[:tweets])
      Tweet.delay(priority: priority).save_new_tweets_and_sync_favorite_tweets

      delay_tweets_processing
    end

    def stats_processing(priority=PRIORITIES[:stats])
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
      RecurringJob.delay_tweets_processing

      # Stats
      Stat.delay_clear_old_seconds_minutes_and_hours_stats
      RecurringJob.delay_stats_processing
    end

    def supervise(max_jobs_allowed=100, too_much_jobs_times=5)#, any_job_not_delayed=20)
      # check if there is no too much delayed jobs
      if too_much_jobs?(max_jobs_allowed, too_much_jobs_times)
        Notify.send("WARNING!!! There is more than #{max_jobs_allowed} delayed jobs, please investigate quickly!")
      end
      # # check if recurring jobs are all delayed
      # if any_job_not_delayed?(NAMES, any_job_not_delayed)
      #   Notify.send("WARNING!!! The following jobs are not delayed: #{not_delayed.join(", ")}; please investigate quickly!")
      # end
    end

    def test_exception
      raise "THIS A DELAYED JOB EXCEPTION TEST"
    end

  private

    def too_much_jobs?(max, times)
      if times.zero?
        true
      else
        if Delayed::Job.count > max
          sleep times
          too_much_jobs?(max, times - 1)
        else
          false
        end
      end
    end

    def any_job_not_delayed?(not_delayed_jobs, times)
      if times.zero?
        true
      else
        not_delayed_jobs -= delayed
        if not_delayed_jobs.any?
          sleep times
          any_job_not_delayed?(not_delayed_jobs, times - 1)
        else
          false
        end
      end
    end

    def delayed
      NAMES.select { |name| Delayed::Job.already_delayed?(name) }
    end

    def not_delayed
      NAMES.reject { |name| Delayed::Job.already_delayed?(name) }
    end

  end
end
