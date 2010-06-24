module VideosHelper
  
  def duration(video)
    return "No duration" if video.blank? || video.duration.blank?
    
    milliseconds_to_duration(video.duration)
  end
  
  def uploaded_on(video)
    video.blank? ? "" : "Uploaded on #{video.created_at.strftime('%d/%m/%Y')}"
  end
  
  def thumbnail_tag(video)
    image_tag(video.thumbnail.url) if video.thumbnail.present?
  end
  
  def video_tags_for(video, *args)
    options = args.extract_options!
<<-EOS
<video class='sublime' poster='http://#{Log::Cloudfront::Download.config[:hostname]}/#{video.thumbnail.path}' width='#{options[:width]}' height='#{options[:height]}'>
  #{video.encodings.inject([]) { |html,f| html << source_tag_for(f) }.join(" ")}
</video>
EOS
  end
  
  def panda_uploader_js(field_id)
    (<<-EOS
    jQuery('##{field_id}').pandaUploader(#{Panda.signed_params('post', '/videos.json',
      { :state_update_url => "http://#{request.host_with_port}/videos/$id/transcoded", :profiles => 'none' }).to_json },
      { upload_button_id:'upload_button',
        upload_progress_id:'upload_indicator',
        upload_filename_id:'upload_filename'
    })
    EOS
    ).html_safe
  end
  
private
  
  def source_tag_for(video_encoding)
    "<source src='http://#{Log::Cloudfront::Download.config[:hostname]}/#{video_encoding.file.path}' type='video/#{video_encoding.extname}' />"
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