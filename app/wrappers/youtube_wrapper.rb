class YouTubeWrapper
  attr_reader :video_id

  def initialize(video_id)
    @video_id = video_id
  end

  def video_title
    video_info.try(:title)
  end

  private

  def video_info
    Librato.increment 'video_info.call', source: 'youtube'
    self.class.client.video_by(video_id)
  rescue OpenURI::HTTPError
  end

  def self.client
    @client ||= YouTubeIt::Client.new
  end

end
