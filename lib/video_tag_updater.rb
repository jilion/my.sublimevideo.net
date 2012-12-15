require_dependency 'pusher_wrapper'
require_dependency 'video_tag_sources_analyzer'
require_dependency 'video_tag_name_fetcher'

VideoTagUpdater = Struct.new(:video_tag) do

  def self.update(site_token, uid, data)
    return unless site = Site.where(token: site_token).first

    video_tag = VideoTag.where(site_id: site.id, uid: uid).first_or_initialize
    new(video_tag).update(data)
  end

  def self.update_name(video_tag_id)
    video_tag = VideoTag.find(video_tag_id)
    new(video_tag).update_name
  end

  def update(data)
    # video_tag.attributes = { name: nil, name_origin: nil }.merge(unalias_data(data))
    video_tag.attributes = unalias_data(data)
    if video_tag.valid? && video_tag.changed?
      set_sources_origin_and_id
      set_name
      PusherWrapper.trigger("private-#{video_tag.site.token}", 'video_tag', video_tag.backbone_data)
      Librato.increment 'video_tag.update'
    end
    video_tag.save
  end

  def update_name
    set_sources_origin_and_id
    set_name
    video_tag.save
  end

  def set_sources_origin_and_id
    VideoTagSourcesAnalyzer.new(video_tag).tap do |sources_analyzer|
      video_tag.sources_id     = sources_analyzer.id
      video_tag.sources_origin = sources_analyzer.origin
    end
  end

  def set_name
    VideoTagNameFetcher.new(video_tag).tap do |name_fetcher|
      video_tag.name        = name_fetcher.name
      video_tag.name_origin = name_fetcher.origin
    end
  end

private

  DICTIONARY = {
    uo: 'uid_origin',
    n:  'name',
    no: 'name_origin',
    p:  'poster_url',
    z:  'size',
    d:  'duration',
    cs: 'current_sources',
    s:  'sources',
    i:  'sources_id',
    io: 'sources_origin',
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
        [key, value.nil? ? nil : unalias_key(value, :origin).to_s]
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

end unless defined? VideoTagUpdater
