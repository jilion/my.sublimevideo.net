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

    def method_missing(name, *args)
      Twitter.send(name.to_sym, *args)
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
