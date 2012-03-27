class Admin::AnalyticsController < AdminController
  
  # GET /analytics
  def index
  end
  
  # GET /analytics/report(?param1=value1)
  def show
    @report = Analytics::Engine.report(params[:report], params[:opts] || {})
  end
  
end