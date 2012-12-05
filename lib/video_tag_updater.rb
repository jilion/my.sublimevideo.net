require_dependency 'pusher_wrapper'

VideoTagUpdater = Struct.new(:site, :uid) do

  def self.update(site_token, uid, data)
    return unless site = Site.where(token: site_token).first

    updater = VideoTagUpdater.new(site, uid)
    updater.update(data)
  end

  def update(data)
    video_tag = VideoTag.where(site_id: site.id, uid: uid).first_or_initialize
    video_tag.attributes = unalias_data(data)
    if video_tag.valid? && video_tag.changed?
      PusherWrapper.delay.trigger("private-#{site.token}", 'video_tag', video_tag.data)
    end
    video_tag.save
  end

private

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

  def unalias_data(data)
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

  def unalias_key(key, namespace = nil)
    if namespace
      DICTIONARY[namespace][key.to_sym].to_sym
    else
      DICTIONARY[key.to_sym].to_sym
    end
  end
end
