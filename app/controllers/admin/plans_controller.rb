class Admin::PlansController < Admin::AdminController

  def index
    @plans = Plan.all
  end

end
