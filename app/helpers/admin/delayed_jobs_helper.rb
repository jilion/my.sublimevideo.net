module Admin::DelayedJobsHelper
  
  def job_name(job)
    case job.name
    when "Module#send_limit_alerts"
      "Limit alerts"
    when "Module#supervise_users"
      "Trial users Supervision"
    when "Module#send_credit_card_expiration"
      "Credit Card expiration"
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
      "Module#send_limit_alerts",
      "Module#supervise_users",
      "Module#send_credit_card_expiration",
      "Class#fetch_download_and_create_new_logs",
      "Class#fetch_and_create_new_logs"
    ].include?(job.name)
  end
  
end
