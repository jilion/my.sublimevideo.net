class Admin::StatsController < Admin::AdminController
  
  before_filter :compute_date_range
  
  def index
    # @data = SiteUsage.started_after(1.month.ago).limit(10)
  end
  
end