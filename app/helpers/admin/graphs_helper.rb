module Admin::GraphsHelper

  def graph_start_date
    range_start_date - (moving_average_length - 1).days
  end

  def graph_end_date
    range_end_date
  end

  def range_start_date
    @range_start_date ||= _range_date(:date_range_from, 2.months.ago.utc).midnight
  end

  def range_end_date
    @range_end_date ||= _range_date(:date_range_to, Time.now.utc.yesterday).end_of_day
  end

  def moving_average_length
    @moving_average_length ||= if params[:moving_avg]
      params[:moving_avg].to_i
    else
      30
    end
  end

  private

  def _range_date(key, default_date = nil)
    if params[key]
      Time.utc(params[key][:year].to_i, params[key][:month].to_i, params[key][:day].to_i)
    else
      default_date
    end
  end

end
