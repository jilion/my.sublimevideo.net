require 'active_support/core_ext'
require 'addressable/uri'

require 'notifier'

class VideoTagTrackersParser

  # Merge each videos tag in one big hash
  #
  # { ['site_token','video_uid'] => { uo: ..., n: ..., cs: ['5062d010',...], s: { '5062d010' => { ...}, ... } } }
  #
  def self.extract_video_tags_data(video_tags_trackers)
    video_tags = Hash.new { |h, k| h[k] = Hash.new }
    video_tags_trackers.each do |request, hits|
      begin
        params = Addressable::URI.parse(request).query_values || {}
        if params['h'].in? %w[m e]
          clean_encoding_video_uid(params)
          case params['e']
          when 'l'
            if all_needed_params_present?(params, %w[vu pz])
              params['vu'].each_with_index do |vu, index|
                video_tags[[params['t'], vu]]['z'] = params['pz'][index]
              end
            end
          when 's'
            if all_needed_params_present?(params, %w[t vu vuo])
              %w[uo i io n no p].each do |key|
                if params.key?("v#{key}")
                  video_tags[[params['t'], params['vu']]][key] = params["v#{key}"]
                end
              end
              # Video duration
              video_tags[[params['t'], params['vu']]]['d'] = params['vd'].try(:to_i)
              # Video current sources
              video_tags[[params['t'], params['vu']]]['cs'] = params['vcs'] || []
              # Video sources
              if params.key?('vc')
                video_tags[[params['t'], params['vu']]]['s'] ||= {}
                video_tags[[params['t'], params['vu']]]['s'][params['vc']] = { 'u' => params['vs'], 'q' => params['vsq'], 'f' => params['vsf'] }
                video_tags[[params['t'], params['vu']]]['s'][params['vc']]['r'] = params['vsr'] if params['vsr'].present?
              end
            end
          end
        end
      rescue => ex
        Notifier.send("VideoTag parsing failed (request: '#{request}'): #{ex.message}", exception: ex)
      end
    end
    video_tags
  end

  def self.all_needed_params_present?(params, keys)
    (params.keys & keys).sort == keys.sort
  end

  def self.clean_encoding_video_uid(params)
    if params['vu'].is_a?(Array)
      params['vu'].map! do |uid|
        return nil unless uid.is_a?(String)
        uid.force_encoding('binary')
        uid.encode('utf-8', :invalid => :replace, :undef => :replace)
      end
    elsif params['vu'].is_a?(String)
      params['vu'].force_encoding('binary')
      params['vu'] = params['vu'].encode('utf-8', :invalid => :replace, :undef => :replace)
    end
  end

end
