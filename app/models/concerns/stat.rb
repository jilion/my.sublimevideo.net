require 'sublime_video_private_api'
require 'time_parsable'

module Stat
  extend ActiveSupport::Concern
  include SublimeVideoPrivateApi::Model
  include TimeParsable

  included do
    uses_private_api :stats
  end
end
