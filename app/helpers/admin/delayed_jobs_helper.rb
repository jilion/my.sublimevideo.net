module Admin::DelayedJobsHelper

  def job_name(job)
    case job.name
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

    when "Module#invoices_processing"
      "Invoices processing"

    when "Module#sites_processing"
      "Sites processing"

    when "Module#users_processing"
      "Users processing"

    when "Module#tweets_processing"
      "Tweets processing"

    when "Module#clear_old_seconds_minutes_and_hours_stats"
      "Clear old site stats"

    when "Module#stats_processing"
      "Stats processing"

    else
      job.name
    end
  end

  def recurring_job?(job)
    %w[
      Class#fetch_and_create_new_logs
      Class#send
      Class#send_credit_card_expiration
      Module#monitor_sites_usages
      Module#invoices_processing
      Module#sites_processing
      Module#users_processing
      Module#tweets_processing
      Module#clear_old_seconds_minutes_and_hours_stats
      Module#stats_processing
    ].include?(job.name)
  end

end
