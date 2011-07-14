module TwitterApi
  class << self

    def consumer_key
      yml[:consumer_key] == 'heroku_env' ? ENV['TWITTER_CONSUMER_KEY'] : yml[:consumer_key]
    end

    def consumer_secret
      yml[:consumer_secret] == 'heroku_env' ? ENV['TWITTER_CONSUMER_SECRET'] : yml[:consumer_secret]
    end

    def oauth_token
      yml[:oauth_token] == 'heroku_env' ? ENV['TWITTER_OAUTH_TOKEN'] : yml[:oauth_token]
    end

    def oauth_token_secret
      yml[:oauth_token_secret] == 'heroku_env' ? ENV['TWITTER_OAUTH_TOKEN_SECRET'] : yml[:oauth_token_secret]
    end

    def search
      Twitter::Search
    end

    def method_missing(method_name, *args)
      if Twitter.respond_to?(method_name)
        rescue_and_retry(3, Errno::ETIMEDOUT, Errno::ECONNRESET, Twitter::BadGateway, Twitter::ServiceUnavailable) do
          Twitter.send(method_name.to_sym, *args)
        end
      else
        super
      end
    end

    def respond_to?(method_name)
      Twitter.respond_to?(method_name) || super
    end

  private

    def yml
      config_path = Rails.root.join('config', 'twitter.yml')
      @yml_options ||= YAML::load_file(config_path)[Rails.env]
      @yml_options.to_options
    rescue
      raise StandardError, "Twitter config file '#{config_path}' doesn't exist."
    end

  end
end
