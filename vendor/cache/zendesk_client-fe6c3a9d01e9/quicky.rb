require "rubygems"
require "faraday"
require "json"
require "base64"

module Zendesk
  class Connection
    def initialize(account, email, password)
      @zen = Faraday.new(:url => "https://#{account}.zendesk.com/") do |config|
        config.request :url_encoded
        config.request :json
        config.response :logger
        config.adapter :net_http
      end
      @zen.basic_auth email, password
      @zen
    end

    # GET resources
    %w[ users organizations groups tickets attachments tags forums entries ticket_fields macros ].each do |resource|
      class_eval <<-METHOD
        def #{resource}
          #{resource} = @zen.get("#{resource}")
          JSON.parse(#{resource}.body)
        end
      METHOD
    end

    # POST resources
#     %w[ user organization group ticket attachment tag forum entry ticket_field macro ].each do |resource|
#       class_eval <<-METHOD
#         def #{resource}(data)
#           @zen.post("/#{resource + 's'}", data)
#         end
#       METHOD
#     end

    # delegate to faraday
    def method_missing(method, *args, &block)
      @zen.send(method, *args, &block)
    end
  end
end
