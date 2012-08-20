require_dependency 'configurator'

class ZendeskConfig
  include Configurator

  config_file 'zendesk.yml'
  config_accessor :base_url, :api_url, :username, :api_token
end
