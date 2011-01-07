class Admin::DashboardsController < Admin::AdminController

  before_filter :compute_date_range

  def show
  end

end
