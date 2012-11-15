# require_dependency 'pusher_wrapper'

class NewVideoTagUpdater
  DICTIONARY = {
    uo: 'uid_origin',
    n:  'name',
    no: 'name_origin',
    i:  'video_id',
    ui: 'video_id_origin',
    p:  'poster_url',
    z:  'size',
    d:  'duration',
    cs: 'current_sources',
    s:  'sources',
    t:  'settings',
    origin: {
      a: 'attribute',
      s: 'source',
      y: 'youtube'
    },
    source: {
      u: 'url',
      q: 'quality',
      f: 'family',
      r: 'resolution'
    }
  }

  def self.update(site_token, uid, data)
    return unless site = Site.where(token: site_token).first
    video_tag = VideoTag.first_or_initialize(site_id: site.id, uid: uid)
    video_tag.attributes = unalias_data(data)
    # if video_tag.valid? && video_tag.changed?
    #   PusherWrapper.trigger("private-#{st}", 'video_tag', u: video_tag.uid, meta_data: video_tag.data)
    # end
    video_tag.save
  end

private

  def self.unalias_data(data)
    Hash[data.map { |key, value|
      case key = unalias_key(key)
      when /origin/
        [key, unalias_key(value, :origin).to_s]
      when :sources
        [key, Hash[value.map { |crc32, source_data|
          [crc32, Hash[source_data.map { |key, value|
            [unalias_key(key, :source), value]
          }]]
        }]]
      else
        [key, value]
      end
    }]
  end

  def self.unalias_key(key, namespace = nil)
    if namespace
      DICTIONARY[namespace][key.to_sym].to_sym
    else
      DICTIONARY[key.to_sym].to_sym
    end
  end
end
