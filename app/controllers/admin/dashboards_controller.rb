class Admin::DashboardsController < Admin::AdminController

  before_filter :compute_date_range

  def show

  end

private

  def compute_date_range
    @date_range_from = if params[:date_range_from]
      DateTime.new(params[:date_range_from][:year].to_i, params[:date_range_from][:month].to_i, params[:date_range_from][:day].to_i)
    else
      1.month.ago - 1.day
    end

    @date_range_to = if params[:date_range_to]
      DateTime.new(params[:date_range_to][:year].to_i, params[:date_range_to][:month].to_i, params[:date_range_to][:day].to_i).end_of_day
    else
      Time.now.yesterday
    end
    
    if params[:date_range_from] || params[:date_range_to]
      expire_fragment('dashboard_users')
      expire_fragment('dashboard_sites')
      expire_fragment('dashboard_usage')
    end
  end

end
