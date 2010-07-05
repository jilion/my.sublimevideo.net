module Admin::DelayedJobsHelper
  
  def job_name(job)
    case job.name
    when "Module#send_limit_alerts"
      "Limit alerts"
    when "Module#supervise_users"
      "Trial users Supervision"
    when "Class#fetch_download_and_create_new_logs", "Class#fetch_and_create_new_logs"
      case job.handler
      when /Log::Voxcast/
        "Voxcast logs"
      when /Log::Amazon::S3::Videos/
        "S3 videos logs"
      when /Log::Amazon::Cloudfront::Streaming/
        "Cloudfront streaming logs"
      when /Log::Amazon::Cloudfront::Download/
        "Cloudfront download logs"
      end
    else
      job.name
    end
  end
  
  def recurring_job?(job)
    [
      "Module#send_limit_alerts",
      "Module#supervise_users",
      "Class#fetch_download_and_create_new_logs",
      "Class#fetch_and_create_new_logs"
    ].include?(job.name)
  end
  
end
