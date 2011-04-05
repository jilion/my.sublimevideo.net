module Admin::DelayedJobsHelper

  def job_name(job)
    case job.name
    when "Module#send_credit_card_expiration"
      "Credit card expiration"
    when "Module#monitor_sites_usages"
      "Usage monitoring"
    when "Class#update_pending_dates_for_non_renew_and_not_paid_invoices"
      "Update non-paid invoices & sites dates"
    when "Class#renew_active_sites!"
      "Renew active sites"
    when "Class#charge_open_invoices"
      "Open invoices charging"
    when "Class#update_last_30_days_counters_for_not_archived_sites"
      "Update last 30 days hits"
    when "Class#create_users_stats"
      "Users stats"
    when "Class#create_sites_stats"
      "Sites stats"
    when "Class#fetch_download_and_create_new_logs", "Class#fetch_and_create_new_logs"
      case job.handler
      when /Log::Voxcast/
        "Voxcast logs"
      when /Log::Amazon::S3::Player/
        "S3 player logs"
      when /Log::Amazon::S3::Loaders/
        "S3 loaders logs"
      when /Log::Amazon::S3::Licenses/
        "S3 licenses logs"
      end
    else
      job.name
    end
  end

  def recurring_job?(job)
    [
      "Module#send_credit_card_expiration",
      "Class#fetch_download_and_create_new_logs",
      "Class#fetch_and_create_new_logs",
      "Module#monitor_sites_usages",
      "Class#charge_open_invoices",
      "Class#update_last_30_days_counters_for_not_archived_sites",
      "Class#renew_active_sites!",
      "Class#create_users_stats",
      "Class#create_sites_stats"
    ].include?(job.name)
  end

end
