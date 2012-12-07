require 'vimeo'

VimeoWrapper = Struct.new(:video_id) do

  def video_title
    video_info.try(:[], "title")
  end

  private

  def video_info
    Librato.increment 'video_info.call', source: 'vimeo'
    Vimeo::Simple::Video.info(video_id).try(:first)
  end

end unless defined? VimeoWrapper
