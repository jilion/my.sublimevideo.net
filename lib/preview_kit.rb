require_dependency 'configurator'

module PreviewKit
  include Configurator

  config_file 'preview_kit.yml', rails_env: false
  config_accessor :kit_names

  def self.kit_identifer(design_name)
    ((kit_names.index(design_name) || 0) + 1).to_s
  end
end
