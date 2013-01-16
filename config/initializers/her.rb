require_dependency 'api/token_authentication'
require_dependency 'api/response_parser'

$www_api = Her::API.new
$www_api.setup url: "http://sublimevideo.dev/api" do |connection|
  connection.use Api::TokenAuthentication, token: (ENV['API_PASSWORD'] || 'sublimevideo')
  connection.use Api::ResponseParser
  connection.use Faraday::Adapter::NetHttp
end

