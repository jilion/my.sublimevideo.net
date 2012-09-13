module VideoTagsHelper

  def videos_table_filter_options_for_select
    options_for_select [
        ['Last 30 days active', :last_30_days_active],
        ['Last 90 days active', :last_90_days_active],
        ['Hosted on SublimeVideo', :hosted_on_sublimevideo],
        ['Non-hosted on SublimeVideo', :not_hosted_on_sublimevideo],
        ['Inactive only', :inactive],
        ['Show all', :all] # inactive include
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

  def playable_lightbox(video_tag, options = {})
    tags = []
    tags << link_to("http://media.jilion.com/vcg/ms_360p.mp4",
      class: 'sublime'
    ) do
      image_tag video_tag.poster(:small), size: options[:size]
    end
    tags << content_tag(:video,
      class: "sublime lightbox",
      poster: video_tag.poster(:large),
      width: 640, height: 360,
      data: { name: video_tag.n, uid: video_tag.u },
      preload: 'none',
      style: 'display:none'
    ) do
      sources = video_tag.sources.map do |source|
        options = { src: source['u'] }
        options[:data] = { quality: 'hd' } if source['q'] == 'hd'
        tag('source', options)
      end
      sources.join.html_safe
    end
    tags.join.html_safe
  end

end
