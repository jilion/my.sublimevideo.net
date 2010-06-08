module VideosHelper
  
  def seconds_to_duration(seconds)
    return "No duration" if seconds.blank?
    seconds = seconds / 1000
    hours                  = seconds / 1.hour
    minutes_in_last_hour   = (seconds - hours.hours) / 1.minute
    seconds_in_last_minute = seconds - hours.hours - minutes_in_last_hour.minutes
    
    if seconds < 1.minute
      "00:#{seconds.to_s.rjust(2, '0')}"
    else
      "#{"#{hours.to_s.rjust(2, '0')}:" if seconds > 1.hour}#{minutes_in_last_hour.to_s.rjust(2, '0')}:#{seconds_in_last_minute.to_s.rjust(2, '0')}"
    end
  end
  
  def panda_uploader_js(field_id)
    <<-EOS
    jQuery('##{field_id}').pandaUploader(#{Panda.signed_params('post', '/videos.json',
      { :state_update_url => "#{HOST}/videos/$id/transcoded", :profiles => '5e08a5612e8982ef2f7482e0782bbe02' }).to_json },
      { upload_button_id:'upload_button',
        upload_progress_id:'upload_indicator',
        upload_filename_id:'upload_filename'
    })
    EOS
  end
  
  def video_tags_for(video, *args)
    options = args.extract_options!
    "<video class='sublime' poster='http://cdn.sublimevideo.net#{video.thumbnail.url}' width='#{options[:width]}' height='#{options[:height]}'>\n#{video.formats.inject([]) { |html,f| html << source_tag_for(f) }.join(" ")}\n</video>"
  end
  
private

  def source_tag_for(video)
    "<source src='http://cdn.sublimevideo.net#{video.file.url}' type='video/#{video.container || 'unknow'}' />"
  end
  
end