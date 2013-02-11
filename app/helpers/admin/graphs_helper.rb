# coding: utf-8
module Admin::GraphsHelper

  def graph_start_date
    range_start_date - (moving_average_length-1).days
  end

  def graph_end_date
    range_end_date
  end

  def range_start_date
    @range_start_date ||= if params[:date_range_from]
      Time.utc(params[:date_range_from][:year].to_i, params[:date_range_from][:month].to_i, params[:date_range_from][:day].to_i)
    else
      2.months.ago.utc
    end.midnight
  end

  def range_end_date
    @range_end_date ||= if params[:date_range_to]
      Time.utc(params[:date_range_to][:year].to_i, params[:date_range_to][:month].to_i, params[:date_range_to][:day].to_i)
    else
      Time.now.utc.yesterday
    end.end_of_day
  end

  def moving_average_length
    @moving_average_length ||= if params[:moving_avg]
      params[:moving_avg].to_i
    else
      30
    end
  end

end
