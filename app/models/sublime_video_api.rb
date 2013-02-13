require 'configurator'

class SublimeVideoApi
  include Configurator

  config_file 'sublime_video_api.yml', rails_env: false
end
