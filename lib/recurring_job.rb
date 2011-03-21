module RecurringJob

  logs_tasks = [
    '%Log::Voxcast%fetch_download_and_create_new_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]

  stats_tasks = [
    '%UsersStat%create_users_stats%'
  ]

  billing_tasks = [
    '%Site%renew_active_sites!%',
    '%Transaction%charge_all_open_and_failed_invoices%'
  ]

  NAMES = [
    '%User::CreditCard%send_credit_card_expiration%',
    '%Site::UsageAlert%send_usage_alerts%',
    '%Site%update_last_30_days_counters_for_not_archived_sites%'
  ] + logs_tasks + billing_tasks + stats_tasks

  class << self

    def launch_all
      # Logs
      Log.delay_fetch_and_create_new_logs

      # Billing
      Site.delay_renew_active_sites!
      Transaction.delay_charge_all_open_and_failed_invoices

      # Stats
      UsersStat.delay_create_users_stats

      # Others
      User::CreditCard.delay_send_credit_card_expiration
      Site::UsageAlert.delay_send_usage_alerts
      Site.delay_update_last_30_days_counters_for_not_archived_sites
    end

    def supervise
      # check if recurring jobs are all delayed twice
      unless all_delayed?
        sleep 10
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

  end
end
