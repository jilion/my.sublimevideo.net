require 'sublime_video_private_api'
require 'time_parsable'

module LastPlay
  extend ActiveSupport::Concern
  include SublimeVideoPrivateApi::Model
  include TimeParsable

  included do
    uses_private_api :stats
  end

  def document_url
    ERB::Util.h(try(:du?))
  end

  def referrer_url
    ERB::Util.h(try(:ru?))
  end

  def referrer_url?
    try(:ru?)
  end

  def video_tag
    @video_tag ||= VideoTag.find(try(:u), _site_token: try(:s))
  end
end
