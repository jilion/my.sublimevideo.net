module VideoTagsHelper

  def videos_table_filter_options_for_select
    options_for_select [
        ['Last 30 days active', :last_30_days_active],
        ['Last 90 days active', :last_90_days_active],
        ['Last 365 days active', :last_365_days_active],
        ['Show all', :all], # inactive include
        ['Inactive only', :inactive]
      ],
      (params[:filter] || :last_30_days_active)
  end

  def last_starts_days
    return 90 if params[:filter].in?(%w[last_90_days_active])
    return 365 if params[:filter].in?(%w[last_365_days_active all inactive])
    30
  end

  def duration_string(duration)
    return '?:??:??' if duration.blank?

    seconds_tot = (duration / 1000.0).ceil
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

  def proxied_image_tag(source, options = {})
    image_url = source.gsub(/^(http)?s?:?\/\//, '')
    url = "https://images.weserv.nl?url=#{URI::escape(image_url)}"
    if options[:size]
      dimension = options[:size].split('x')
      url += "&w=#{dimension[0]}&h=#{dimension[1]}"
    end
    image_tag(url, options)
  end

end
