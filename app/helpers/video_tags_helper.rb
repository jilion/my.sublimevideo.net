module VideoTagsHelper

  def videos_table_filter_options_for_select
    options_for_select [
      ['Last 30 days active', :last_30_days_active],
      ['Last 90 days active', :last_90_days_active],
      ['Hosted on SublimeVideo', :hosted_on_sublimevideo],
      ['Non-hosted on SublimeVideo', :not_hosted_on_sublimevideo],
      ['Inactive only', :inactive],
      ['Show all', :all] # inactive include
    ]
  end

  def duration_string(duration)
    seconds_tot = duration / 1000
    seconds = seconds_tot % 60
    minutes_tot = seconds_tot / 60
    minutes = minutes_tot % 60
    hours = minutes_tot / 60

    string = []
    string << hours if hours > 0
    string << (minutes < 10 ? "0#{minutes}" : minutes)
    string << (seconds < 10 ? "0#{seconds}" : seconds)
    string.join(':')
  end

end
