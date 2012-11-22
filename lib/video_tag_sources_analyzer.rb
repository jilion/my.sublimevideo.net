VideoTagSourcesAnalyzer = Struct.new(:video_tag) do

  self::VIMEO_URL_PART = 'player.vimeo.com/external'

  def initialize(*args)
    super
    analyze
  end

  def origin
    @origin || video_tag.sources_origin
  end

  def id
    @id || video_tag.sources_id
  end

private

  def analyze
    unless video_tag.sources_origin
      if vimeo_source?
        @origin = "vimeo"
        @id = sources_urls.first.match(%r{//#{self.class::VIMEO_URL_PART}/(\d+)\..*})[1]
      else
        @origin = "other"
      end
    end
  end

  def sources_urls
    video_tag.used_sources.map { |key, value| value[:url] }
  end

  def vimeo_source?
    puts sources_urls.first

    sources_urls.first.include?(self.class::VIMEO_URL_PART)
  end

end
