class Admin::DelayedJobsController < Admin::AdminController
  
  # GET /admin/djs
  def index
    @delayed_jobs = Delayed::Job.order(sort_from_params).all
    respond_with(@delayed_jobs)
  end
  
  # GET /admin/djs/1
  def show
    @delayed_job  = Delayed::Job.find(params[:id])
    respond_with(@delayed_job)
  end
  
protected
  
  def sort_from_params
    if key = params.keys.select{ |k| k =~ /by_(\w)+/ }.try(:first)
      key.sub('by_', '').to_sym.send(params[key.to_sym])
    else
      :created_at.desc
    end
  end
  
end