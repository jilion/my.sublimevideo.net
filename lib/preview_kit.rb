require_dependency 'configurator'

module PreviewKit
  include Configurator

  config_file 'preview_kit.yml', rails_env: false
  config_accessor :kit_ids

end
