require_dependency 'configurator'

class AdminRole
  include Configurator

  config_file 'admin_role.yml', rails_env: false
end
