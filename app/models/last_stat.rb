require 'sublime_video_private_api'
require 'time_parsable'

class LastStat
  include SublimeVideoPrivateApi::Model
  include TimeParsable

  uses_private_api :stats
end
