module VideoTagsHelper

  def videos_table_filter_options_for_select
    options_for_select [
        ['Last 30 days active', :last_30_days_active],
        ['Last 90 days active', :last_90_days_active],
        ['Last 365 days active', :last_365_days_active],
      ],
      (params[:filter] || :last_30_days_active)
  end

  def last_starts_days
    case params[:filter]
    when 'last_90_days_active' then 90
    when 'last_365_days_active' then 365
    else 30
    end
  end

  def last_grouped_starts(starts, days)
    starts = starts.last(days)
    case days
    when 30 then starts
    when 90 then starts.each_slice(2).map { |s| s.sum }
    when 365 then starts.each_slice(5).map { |s| s.sum }
    end
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

  def video_tag_thumbnail(video_tag, options = {})
    if video_tag.poster_url?
      proxied_image_tag(video_tag.poster_url, options)
    else
      image_tag('video_tag/no-poster.png', { alt: 'no poster' }.merge(options))
    end
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
