require 'sublime_video_private_api'
require 'time_parsable'

class LastPlay
  include SublimeVideoPrivateApi::Model
  include TimeParsable

  uses_private_api :stats

  def document_url
    ERB::Util.h(du)
  end

  def referrer_url
    ERB::Util.h(ru)
  end

  def video_tag
    @video_tag ||= VideoTag.find(u, _site_token: s)
  end
end
