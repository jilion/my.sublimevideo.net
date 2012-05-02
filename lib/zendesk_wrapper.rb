require 'zendesk'
require 'net/http'
require 'securerandom'
require 'delegate'
require 'rescue_me'
require 'json'
require 'hashie/mash'

module ZendeskWrapper

  class << self

    def tickets(*args)
      # TODO: client.tickets() doesn't work... :'(
      # client.tickets(*args)
    end

    def ticket(id)
      client.tickets(id).fetch
    end

    def create_ticket(params)
      # TODO: client.tickets.create() doesn't return the created ticket... :'(
      # response = client.tickets.create(params)
      # ticket(extract_ticket_id_from_location(response.location))
      response = post('/tickets', Faraday::Utils.build_nested_query(ticket: params))
      ticket(extract_ticket_id_from_location(response.location))
    end

    def user(id)
      client.users(id).fetch
    end

    def create_user(user)
      params = { email: user.email, name: user.name, password: SecureRandom.hex(13), is_verified: true }
      params[:name] = user.email if user.name.nil? || user.name.empty?
      client.users.create(params)
    end

    def update_user(user_id, params)
      if params[:email]
        post("/users/#{user_id}/user_identities", Faraday::Utils.build_nested_query(params.merge(is_verified: true)))
        identity_id = client.users(user_id).identities.fetch.last.id
        post("/users/#{user_id}/user_identities/#{identity_id}/make_primary")
      else
        client.users(user_id).update(params)
      end
    end

    def search(*args)
      # TODO: client.search() isn't implemented... :'(
      # client.search(*args)
      params = args.pop.inject([]) { |memo, (k,v)| memo << "#{k}:#{v}"}
      page, results = 1, []
      begin
        r = get("/search?query=#{params.join('&')}&order_by=created_at&sort=asc&page=#{page}").body
        results += r
        page += 1
      end while r.size > 0

      Tickets.new(results)
    end

    def verify_user(requester_id)
      user(requester_id).update(password: SecureRandom.hex(13), is_verified: true)
    end

    private

    def client
      @client ||= Zendesk::Client.new do |config|
        config.account = ZendeskConfig.api_url
        config.adapter = :net_http
        config.basic_auth "#{ZendeskConfig.username}/token", ZendeskConfig.api_token
      end
    end

    def get(url, params = {})
      Request.new(url, :Get, params).execute
    end

    def post(url, params = {})
      Request.new(url, :Post, params).execute
    end

    def extract_ticket_id_from_location(location)
      location[%r{/tickets/(\d+)\.json}, 1].to_i
    end

  end

  class Request
    def initialize(path, verb, params = {})
      @verb    = verb
      @uri     = URI.parse("#{ZendeskConfig.api_url}#{path}")
      @request = Net::HTTP.const_get(@verb.to_s).new(@uri.request_uri)
      @request.basic_auth("#{ZendeskConfig.username}/token", ZendeskConfig.api_token)
      @request['accept'] = 'application/json'
      unless params.empty?
        @request.body         = params
        @request.content_type = 'application/x-www-form-urlencoded'
      end
    end

    def execute
      rescue_and_retry(5, Net::HTTPServerException) do
        http_response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
          http.request(@request)
        end

        Response.new(http_response)
      end
    end
  end

  class Response < SimpleDelegator
    # Takes a Net::HTTPResponse as only params
    def initialize(http_response)
      super(http_response)
      @body = JSON[http_response.body] rescue nil
    end

    def code
      super.to_i
    end

    def location
      self['location']
    end

    def body
      @body
    end

  end

  class Ticket < SimpleDelegator

    # Takes a Hashie::Mash as only params
    def initialize(hash)
      super(hash)
    end

    def id
      nice_id
    end

    def to_params
      { id: id, requester_id: requester_id, subject: subject, message: description, comments: comments }
    end

    def verify_user
      ZendeskWrapper.verify_user(requester_id)
    end

  end

  # This shouldn't be needed anymore once ZendeskWrapper.tickets
  # will work as expected
  class Tickets
    include Enumerable

    # Takes an Array of hash as only params
    def initialize(array)
      @tickets = []
      array.each do |hash|
        @tickets << Ticket.new(Hashie::Mash.new(hash))
      end
    end

    def each
      @tickets.each { |ticket| yield ticket }
    end

  end

end
