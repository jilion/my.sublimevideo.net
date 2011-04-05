module RecurringJob

  logs_tasks = [
    '%Log::Voxcast%fetch_download_and_create_new_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]

  stats_tasks = [
    '%UsersStat%create_users_stats%',
    '%SitesStat%create_sites_stats%'
  ]

  billing_tasks = [
    '%Invoice%update_pending_dates_for_non_renew_and_not_paid_invoices%',
    '%Site%renew_active_sites!%',
    '%Transaction%charge_open_invoices%'
  ]

  NAMES = [
    '%User::CreditCard%send_credit_card_expiration%',
    '%Site::UsageMonitoring%monitor_sites_usages%',
    '%Site%update_last_30_days_counters_for_not_archived_sites%'
  ] + logs_tasks + billing_tasks + stats_tasks

  class << self

    def launch_all
      # Logs
      Log.delay_fetch_and_create_new_logs

      # Billing
      Invoice.delay_update_pending_dates_for_non_renew_and_not_paid_invoices
      Site.delay_renew_active_sites!
      Transaction.delay_charge_open_invoices

      # Stats
      UsersStat.delay_create_users_stats
      SitesStat.delay_create_sites_stats

      # Others
      User::CreditCard.delay_send_credit_card_expiration
      Site::UsageMonitoring.delay_monitor_sites_usages
      Site.delay_update_last_30_days_counters_for_not_archived_sites
    end

    def supervise
      # check if there is no too much delayed jobs
      max_jobs_allowed = 50
      if too_much_jobs?(max_jobs_allowed)
        Notify.send("WARNING!!! There is more than #{max_jobs_allowed} delayed jobs, please investigate quickly!")
      end
      # check if recurring jobs are all delayed twice
      unless all_delayed?
        sleep 20
        unless all_delayed?
          Notify.send("WARNING!!! All recurring jobs are not delayed, please investigate quickly!")
        end
      end
    end

    def test_exception
      raise "THIS A DELAYED JOB EXCEPTION TEST"
    end

  private

    def all_delayed?
      NAMES.all? { |name| Delayed::Job.already_delayed?(name) }
    end

    def too_much_jobs?(max)
      Delayed::Job.count > max
    end

  end
end
