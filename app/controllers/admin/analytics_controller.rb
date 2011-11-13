class Admin::AnalyticsController < Admin::AdminController
  
  # GET /admin/analytics
  def index
  end
  
  # GET /admin/analytics/report(?param1=value1)
  def show
    @report = Analytics::Engine.report(params[:report], params[:opts] || {})
  end
  
end