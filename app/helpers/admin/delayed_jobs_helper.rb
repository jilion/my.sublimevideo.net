module Admin::DelayedJobsHelper

  def job_name(job)
    case job.name
    when "Module#send_credit_card_expiration"
      "Credit card expiration"
    when "Module#monitor_sites_usages"
      "Usage monitoring"
    when "Module#invoices_processing"
      "Invoices processing"
    when "Class#create_users_stats"
      "Users stats"
    when "Class#create_sites_stats"
      "Sites stats"
    when "Class#save_new_tweets_and_sync_favorite_tweets"
      "Tweets processing"
    when "Module#clear_old_seconds_minutes_and_hours_stats"
      "Clear old site stats"
    when "Class#update_last_30_days_counters_for_not_archived_sites"
      "Update last 30 days hits"
    when "Class#send"
      case job.handler
      when /download_and_create_new_non_ssl_logs/
        "Voxcast logs"
      when /download_and_create_new_ssl_logs/
        "Voxcast SSL logs"
      end
    when "Class#fetch_and_create_new_logs"
      case job.handler
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
    %w[
      Module#send_credit_card_expiration
      Module#monitor_sites_usages
      Module#invoices_processing
      Module#clear_old_seconds_minutes_and_hours_stats
      Class#create_users_stats
      Class#create_sites_stats
      Class#save_new_tweets_and_sync_favorite_tweets
      Class#update_last_30_days_counters_for_not_archived_sites
      Class#fetch_and_create_new_logs
      Class#send
    ].include?(job.name)
  end

end
