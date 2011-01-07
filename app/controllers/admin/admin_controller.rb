class Admin::AdminController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!

  layout 'admin'

  def compute_date_range
    @date_range_from = if params[:date_range_from]
      Time.new(params[:date_range_from][:year].to_i, params[:date_range_from][:month].to_i, params[:date_range_from][:day].to_i)
    else
      1.month.ago - 1.day
    end.midnight

    @date_range_to = if params[:date_range_to]
      Time.new(params[:date_range_to][:year].to_i, params[:date_range_to][:month].to_i, params[:date_range_to][:day].to_i)
    else
      Time.now.yesterday
    end.end_of_day

    if params[:date_range_from] || params[:date_range_to]
      expire_fragment('dashboard_timeline_usage')
      expire_fragment('dashboard_box_users')
      expire_fragment('dashboard_box_sites')
      expire_fragment('dashboard_box_usage')
    end
  end

end
