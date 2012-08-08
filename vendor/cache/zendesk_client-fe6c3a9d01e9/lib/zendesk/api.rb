module Zendesk
  class API # inherited by Client
    attr_accessor *Config::VALID_OPTIONS_KEYS

    # Zendesk::Client.new
    def initialize(options={})
      options = Zendesk.options.merge(options)
      Config::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end

      yield self if block_given?
    end

    def basic_auth(email, password)
      @email, @password = email, password
    end

    def inspect
      "#<#{self.class} @account=#{account} @email=#{email} @password=********* @cache=#{@cache || {}} @format=#{format}>"
    end
  end
end
