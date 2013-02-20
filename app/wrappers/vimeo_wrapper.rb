class VimeoWrapper
  attr_reader :video_id

  def initialize(video_id)
    @video_id = video_id
  end

  def video_title
    video_info.try(:[], "title")
  end

  private

  def video_info
    Librato.increment 'video_info.call', source: 'vimeo'
    Vimeo::Simple::Video.info(video_id).try(:first)
  end

end
