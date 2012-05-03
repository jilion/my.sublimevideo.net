# coding: utf-8

module Admin::AdminHelper

  def current_utc_time
    "Current UTC time: #{l(Time.now.utc, format: :seconds_timezone)}"
  end

  def viped(user)
    if user.vip?
      raw "★#{yield}★"
    else
      yield
    end
  end

end
