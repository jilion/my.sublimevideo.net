module VideosHelper
  
  def duration(video)
    return "No duration" if video.blank? || video.duration.blank?
    
    milliseconds_to_duration(video.duration)
  end
  
  def uploaded_on(video)
    video.blank? ? "" : "Uploaded on #{video.created_at.strftime('%d/%m/%Y')}"
  end
  
  def posterframe_thumb_tag(video)
    image_tag(video.posterframe.thumb.url) if video.posterframe.present?
  end
  
  def video_tags_for(video, *args)
    options = args.extract_options!
    sizes = sizes_in_embed(video)
    <<-EOS
<video class="sublime" poster="http://#{Log::Amazon::Cloudfront::Download.config[:hostname]}/#{video.posterframe.path}" width="#{sizes[:width]}" height="#{sizes[:height]}" controls preload="none">
#{video.encodings.inject([]) { |html,f| html << source_tag_for(f) }}</video>
    EOS
  end
  
  def panda_uploader_js(field_id)
    (<<-EOS
    jQuery('##{field_id}').pandaUploader(#{Panda.signed_params('post', '/videos.json',
      { :state_update_url => "http://#{request.host_with_port}/videos/$id/transcoded", :profiles => "none" }).to_json },
      { upload_button_id: "upload_button",
        upload_progress_id: "upload_indicator",
        upload_filename_id: "upload_filename"
    })
    EOS
    ).html_safe
  end
  
  def sizes_in_embed(video)
    return { :width => 0, :height => 0 } if video.blank?
    max_sized_encoding = video.encodings.where(:width => video.encodings.maximum(:width)).first
    embed_width        = max_sized_encoding.width > video.user.default_video_embed_width ? video.user.default_video_embed_width : max_sized_encoding.width
    embed_height       = (embed_width*max_sized_encoding.height)/max_sized_encoding.width
    { :width => embed_width, :height => embed_height }
  end
  
private
  
  def source_tag_for(video_encoding)
    <<-EOS
  <source src="http://#{Log::Amazon::Cloudfront::Download.config[:hostname]}/#{video_encoding.file.path}" type="video/#{video_encoding.extname}" />
    EOS
  end
  
  def milliseconds_to_duration(milliseconds)
    seconds_to_duration(milliseconds / 1000)
  end
  
  def seconds_to_duration(seconds)
    seconds = seconds
    hours                  = seconds / 1.hour
    minutes_in_last_hour   = (seconds - hours.hours) / 1.minute
    seconds_in_last_minute = seconds - hours.hours - minutes_in_last_hour.minutes
    
    if seconds < 1.minute
      "00:#{seconds.to_s.rjust(2, '0')}"
    else
      "#{"#{hours.to_s.rjust(2, '0')}:" if seconds > 1.hour}#{minutes_in_last_hour.to_s.rjust(2, '0')}:#{seconds_in_last_minute.to_s.rjust(2, '0')}"
    end
  end
  
end