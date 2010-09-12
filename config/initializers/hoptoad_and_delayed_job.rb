class Delayed::Worker
  def handle_failed_job_with_hoptoad(job, error)
    HoptoadNotifier.notify(error)
    handle_failed_job_without_hoptoad(job, error)
  end
  
  alias_method_chain :handle_failed_job, :hoptoad
end