# coding: utf-8

module Admin::AdminHelper

  def current_utc_time
    "Current UTC time: #{l(Time.now.utc, format: :seconds_timezone)}"
  end

end
