module VideosHelper
  
  def seconds_to_duration(seconds)
    return "No duration" if seconds.blank?
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
    $('##{field_id}').pandaUploader(#{Panda.signed_params('post', '/videos.json',
      { :profiles => Video.panda_profiles_ids, :state_update_url => "#{HOST}/videos/$id/transcoded" }).to_json },
      { upload_button_id:'upload_button',
        upload_progress_id:'upload_progress',
        upload_filename_id:'upload_filename',
        api_url:'#{Panda.api_url}'
    })
    EOS
  end
  
end