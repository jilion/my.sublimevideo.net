class Admin::DelayedJobsController < Admin::AdminController
  respond_to :html
  respond_to :js, :only => :index
  
  before_filter :find_by_id, :only => [:show, :update, :destroy]
  
  # GET /admin/djs
  def index
    @delayed_jobs = Delayed::Job.order(sort_from_params)
    respond_with(@delayed_jobs)
  end
  
  # GET /admin/djs/1
  def show
    respond_with(@delayed_job)
  end
  
  # PUT /admin/djs/1
  def update
    @delayed_job.update_attributes(:locked_at => nil, :locked_by => nil)
    respond_with(@site, :location => admin_delayed_jobs_path)
  end
  
  # DELETE /admin/djs/1
  def destroy
    @delayed_job.destroy
    respond_with(@site, :location => admin_delayed_jobs_path)
  end
  
protected
  
  def find_by_id
    @delayed_job = Delayed::Job.find(params[:id])
  end
  
  def sort_from_params
    if key = params.keys.detect { |k| k =~ /^by_(\w+)$/ }
      $1.to_sym.send(params[key.to_sym])
    else
      :created_at.desc
    end
  end
  
end