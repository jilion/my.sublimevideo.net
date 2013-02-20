class VideoTagNameFetcher
  attr_reader :video_tag

  def initialize(video_tag)
    @video_tag = video_tag
    fetch
  end

  def name
    @name || video_tag.name
  end

  def origin
    @origin || video_tag.name_origin
  end

  private

  def fetch
    unless video_tag.name_origin == 'attribute'
      @name = case video_tag.sources_origin
      when 'vimeo'
        VimeoWrapper.new(video_tag.sources_id).video_title
      when 'youtube'
        YouTubeWrapper.new(video_tag.sources_id).video_title
      end
      @origin = video_tag.sources_origin if @name
    end
  end

end
