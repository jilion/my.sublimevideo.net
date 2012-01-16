module TwitterApi
  include Configurator

  heroku_config_file 'twitter.yml'

  heroku_config_accessor 'TWITTER', :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret

  class << self

    def search
      Twitter::Search
    end

    def method_missing(method_name, *args)
      method_name = method_name.to_sym

      if Twitter.respond_to?(method_name)
        begin
          with_rescue_and_retry(3) do
            Twitter.send(method_name, *args)
          end
        rescue => ex
          # Notify.send("Exception during call to Twitter: #{ex.message}", exception: ex)
          nil
        end
      else
        super
      end
    end

    def respond_to?(method_name)
      method_name = method_name.to_sym

      Twitter.respond_to?(method_name) || super
    end

    def with_rescue_and_retry(times)
      rescue_and_retry(times, Errno::ETIMEDOUT, Errno::ECONNRESET, Twitter::BadGateway, Twitter::ServiceUnavailable, Twitter::InternalServerError) do
        yield
      end
    end

  end

end
