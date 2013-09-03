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

  def playable_lightbox(video_tag, options = {})
    tags = []
    tags << link_to('//dehqkotcrv4fy.cloudfront.net/vcg/ms_360p.mp4', class: 'sublime') do
      # TO DO USE SSL PROXY (data.sv.net)
      image_tag(video_tag.poster_url, size: options[:size])
    end
    tags << content_tag(:video,
                        class: 'sublime lightbox',
                        # TO DO USE SSL PROXY (data.sv.net)
                        poster: video_tag.poster_url,
                        width: 640, height: 360,
                        title: video_tag.title,
                        data: { uid: video_tag.uid },
                        preload: 'none',
                        style: 'display:none') do
      sources = video_tag.sources.map do |source|
        options = { src: source[:url] }
        options[:data] = { quality: 'hd' } if source[:quality] == 'hd'
        tag('source', options)
      end
      sources.join.html_safe
    end
    tags.join.html_safe
  end

end
