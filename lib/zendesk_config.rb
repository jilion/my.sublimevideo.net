class ZendeskConfig
  include Configurator

  heroku_config_file 'zendesk.yml'

  heroku_config_accessor 'ZENDESK', :base_url, :api_url, :username, :api_token
end
