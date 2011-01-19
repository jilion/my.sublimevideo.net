class Admin::StatsController < Admin::AdminController
  
  before_filter :compute_date_range
  
  def index
  end
  
end