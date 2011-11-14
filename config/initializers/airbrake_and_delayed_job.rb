class Delayed::Worker

  alias_method :original_handle_failed_job, :handle_failed_job

  def handle_failed_job(job, error)
    Airbrake.notify(error, parameters: { job: job.attributes })
    original_handle_failed_job(job, error)
  end

end