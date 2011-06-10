module Admin::DelayedJobsHelper

  def job_name(job)
    case job.name
    when "Module#send_credit_card_expiration"
      "Credit card expiration"
    when "Module#monitor_sites_usages"
      "Usage monitoring"
    when "Class#update_pending_dates_for_first_not_paid_invoices"
      "Update first non-paid invoices & sites dates"
    when "Class#renew_active_sites!"
      "Renew active sites"
    when "Class#charge_invoices"
      "Invoices charging"
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
    when "Class#save_new_tweets_and_sync_favorite_tweets"
      "Save tweets & sync favorites"
    else
      job.name
    end
  end

  def recurring_job?(job)
    %w[
      Module#send_credit_card_expiration
      Class#fetch_download_and_create_new_logs
      Class#fetch_and_create_new_logs
      Module#monitor_sites_usages
      Class#charge_invoices
      Class#update_last_30_days_counters_for_not_archived_sites
      Class#update_pending_dates_for_first_not_paid_invoices
      Class#renew_active_sites!
      Class#create_users_stats
      Class#create_sites_stats
      Class#save_new_tweets_and_sync_favorite_tweets
    ].include?(job.name)
  end

end
