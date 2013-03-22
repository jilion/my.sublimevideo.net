Twitter.configure do |config|
  config.consumer_key       = TwitterWrapper.consumer_key
  config.consumer_secret    = TwitterWrapper.consumer_secret
  config.oauth_token        = TwitterWrapper.oauth_token
  config.oauth_token_secret = TwitterWrapper.oauth_token_secret
end

# Monkey patching to work around this: https://dev.twitter.com/discussions/15989
module Twitter
  class Client
    def request(method, path, params={}, signature_params=params)
      connection.send(method.to_sym, path, params) do |request|
        request.headers[:authorization] = auth_header(method.to_sym, path, signature_params).to_s
        request.headers['accept-encoding'] = ""  ## Disable gzip encoding in responses
      end.env
    rescue Faraday::Error::ClientError
      raise Twitter::Error::ClientError
    rescue MultiJson::DecodeError
      raise Twitter::Error::DecodeError
    end
  end
end