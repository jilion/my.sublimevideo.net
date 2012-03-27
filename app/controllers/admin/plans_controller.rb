class Admin::PlansController < AdminController
  before_filter { |controller| require_role?('god') }

  # GET /plans
  def index
    @plans = Plan.all
  end

  # GET /plans/new
  def new
    @plan = Plan.new
  end

  # POST /plans
  def create
    @plan = Plan.create_custom(params[:plan])
    respond_with(@plan, location: [:admin, :plans])
  end

end
