require 'configurator'

module TwitterWrapper
  include Configurator

  config_file 'twitter.yml'
  config_accessor :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret

  class << self

    def method_missing(method_name, *args)
      method_name = method_name.to_sym

      if Twitter.respond_to?(method_name)
        begin
          with_rescue_and_retry(7) do
            Twitter.send(method_name, *args)
          end
        rescue Twitter::Error::TooManyRequests => error
          Notifier.send("Too many Twitter requests.")
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
      rescue_and_retry(times, Errno::ETIMEDOUT, Errno::ECONNRESET, Twitter::Error::BadGateway, Twitter::Error::ServiceUnavailable, Twitter::Error::InternalServerError, Twitter::Error::ClientError) do
        yield
      end
    end

  end

end
