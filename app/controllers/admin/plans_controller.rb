class Admin::PlansController < Admin::AdminController
  before_filter { |controller| require_role?('god') }

  # GET /plans
  def index
    @plans = Plan.all
  end

end
