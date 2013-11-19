require 'twitter'
require 'rescue_me'
require 'notifier'

module TwitterWrapper

  def self.method_missing(method_name, *args)
    method_name = method_name.to_sym

    if client.respond_to?(method_name)
      begin
        with_rescue_and_retry(7) do
          client.send(method_name, *args)
        end
      rescue Twitter::Error::TooManyRequests => error
        Notifier.send('Too many Twitter requests.')
      end
    else
      super
    end
  end

  def self.respond_to?(method_name)
    method_name = method_name.to_sym

    client.respond_to?(method_name) || super
  end

  def self.with_rescue_and_retry(times)
    rescue_and_retry(times, Errno::ETIMEDOUT, Errno::ECONNRESET, Twitter::Error::BadGateway, Twitter::Error::ServiceUnavailable, Twitter::Error::InternalServerError, Twitter::Error) do
      yield
    end
  end

  def self.client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
      config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end
  end

end
