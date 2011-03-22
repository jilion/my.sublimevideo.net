class Admin::PlansController < Admin::AdminController

  # GET /admin/plans
  def index
    @plans = Plan.all
  end

  # GET /admin/plans/new
  def new
    @plan = Plan.new
  end

  # POST /admin/plans
  def create
    @plan = Plan.create_custom(params[:plan])
    respond_with(@plan, :location => [:admin, :plans])
  end

end
