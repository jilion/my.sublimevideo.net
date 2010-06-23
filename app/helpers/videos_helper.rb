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
    "<video class='sublime' poster='http://cdn.sublimevideo.net#{video.thumbnail.url}' width='#{options[:width]}' height='#{options[:height]}'>\n#{video.encodings.inject([]) { |html,f| html << source_tag_for(f) }.join(" ")}\n</video>"
  end
  
  def panda_uploader_js(field_id)
    (<<-EOS
    jQuery('##{field_id}').pandaUploader(#{Panda.signed_params('post', '/videos.json',
      { :state_update_url => "#{HOST}/videos/$id/transcoded", :profiles => '5e08a5612e8982ef2f7482e0782bbe02' }).to_json },
      { upload_button_id:'upload_button',
        upload_progress_id:'upload_indicator',
        upload_filename_id:'upload_filename'
    })
    EOS
    ).html_safe
  end
  
private
  
  def source_tag_for(video_encoding)
    "<source src='http://cdn.sublimevideo.net#{video_encoding.file.url}' type='video/#{video_encoding.type || 'unknow'}' />"
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