class Admin::AdminController < ApplicationController
  respond_to :html
  
  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!
  
  layout 'admin'
  
  private
  
  def compute_date_range
    @date_range_from = if params[:date_range_from]
      Time.utc(params[:date_range_from][:year].to_i, params[:date_range_from][:month].to_i, params[:date_range_from][:day].to_i)
    else
      1.month.ago.utc
    end.midnight

    @date_range_to = if params[:date_range_to]
      Time.utc(params[:date_range_to][:year].to_i, params[:date_range_to][:month].to_i, params[:date_range_to][:day].to_i)
    else
      Time.now.utc.yesterday
    end.end_of_day
    
    @moving_avg = if params[:moving_avg]
      params[:moving_avg].to_i
    else
      10
    end
  end
  
end