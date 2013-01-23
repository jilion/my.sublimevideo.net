require_dependency 'api/token_authentication'
require_dependency 'api/response_parser'
require_dependency 'api/url'

ssl_options = { ca_path: '/usr/lib/ssl/certs' }

$www_api = Her::API.new
$www_api.setup url: Api::Url.new('www').url, ssl: ssl_options do |connection|
  connection.use Api::TokenAuthentication, token: (ENV['API_PASSWORD'] || 'sublimevideo')
  connection.use Her::Middleware::AcceptJSON
  connection.use Api::ResponseParser
  connection.use Faraday::Request::UrlEncoded
  connection.use Faraday::Adapter::NetHttp
end
