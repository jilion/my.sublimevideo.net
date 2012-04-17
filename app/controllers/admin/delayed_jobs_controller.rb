class Admin::DelayedJobsController < Admin::AdminController
  respond_to :html
  respond_to :js, only: :index

  before_filter { |controller| require_role?('god') }
  before_filter :find_by_id, only: [:show, :update, :destroy]

  # GET /djs
  def index
    @delayed_jobs = Delayed::Job.order(sort_from_params)
    respond_with(@delayed_jobs)
  end

  # GET /djs/:id
  def show
    respond_with(@delayed_job)
  end

  # PUT /djs/:id
  def update
    @delayed_job.update_attributes(locked_at: nil, locked_by: nil)
    respond_with(@site, location: admin_delayed_jobs_path(sort_params))
  end

  # DELETE /djs/:id
  def destroy
    @delayed_job.destroy
    respond_with(@site, location: admin_delayed_jobs_path(sort_params))
  end

private

  def sort_params
    params.select { |k, v| k =~ /^by_\w+$/ }
  end
  helper_method :sort_params

  def find_by_id
    @delayed_job = Delayed::Job.find(params[:id])
  end

  def sort_from_params
    if param = sort_params.first
      param[0].sub('by_', '').to_sym.send(param[1])
    else
      :run_at.asc
    end
  end

end
