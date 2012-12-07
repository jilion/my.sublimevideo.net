require 'youtube_it'

YouTubeWrapper = Struct.new(:video_id) do

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

end unless defined? YouTubeWrapper
