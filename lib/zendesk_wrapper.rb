require 'zendesk_api'
require 'tempfile' # won't be needed after 0.1.2 of zendesk_api
require_dependency 'configurator'

module ZendeskWrapper
  include Configurator

  config_file 'zendesk.yml'
  config_accessor :base_url, :api_url, :username, :api_token

  class << self

    def tickets
      client.tickets
    end

    def ticket(id)
      tickets.find(id: id)
    end

    def create_ticket(params)
      uploads = params.delete(:uploads) || []

      ticket = ZendeskAPI::Ticket.new(client, params)

      save_ticket_with_uploads!(ticket, uploads)
    end

    def user(id)
      client.users.find(id: id)
    end

    def create_user(user)
      params = { external_id: user.id, email: user.email, name: user.name_or_email, verified: true }
      client.users.create(params)
    end

    def update_user(user_id, params)
      if params[:email]
        user(user_id).identities.create(type: 'email', value: params[:email], verified: true)
        user(user_id).identities.last.make_primary
      end

      if params[:name]
        u = user(user_id)
        u.name = params[:name]
        u.save
      end
    end

    def destroy_user(user_id)
      user(user_id).destroy
    end

    def search(*args)
      client.search(*args)
    end

    def verify_user(requester_id)
      user(requester_id).verify
    end

    private

    def client
      @client ||= ZendeskAPI::Client.new do |config|
        config.url      = self.api_url
        config.username = "#{self.username}/token"
        config.password = self.api_token

        # Retry uses middleware to notify the user
        # when hitting the rate limit, sleep automatically,
        # then retry the request.
        config.retry = true

        # Logger prints to STDERR by default, to e.g. print to stdout:
        # require 'logger'
        # config.logger = Logger.new(STDOUT)
      end
    end

    def save_ticket_with_uploads!(ticket, uploads)
      uploads.each do |upload|
        ticket.comment.uploads << { file: upload.path, filename: upload.original_filename }
      end

      ticket.save!
      ticket
    end

    def extract_ticket_id_from_location(location)
      location[%r{/tickets/(\d+)\.json}, 1].to_i
    end

  end

end
