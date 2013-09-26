require 'zendesk_api'

module ZendeskWrapper

  def self.tickets
    client.tickets
  end

  def self.ticket(id)
    tickets.find(id: id)
  end

  def self.create_ticket(params)
    uploads = params.delete(:uploads) || []

    ticket = ZendeskAPI::Ticket.new(client, params)

    save_ticket_with_uploads!(ticket, uploads)
  end

  def self.user(id)
    client.users.find(id: id)
  end

  def self.create_user(user)
    params = { external_id: user.id, email: user.email, name: user.name_or_email, verified: true }
    client.users.create(params)
  end

  def self.update_user(user_id, params)
    if params[:email]
      user(user_id).identities.create(type: 'email', value: params[:email])
      identity = user(user_id).identities.last
      identity.verify
      identity.make_primary
    end

    if params[:name]
      u = user(user_id)
      u.name = params[:name]
      u.save
    end
  end

  def self.destroy_user(user_id)
    user(user_id).destroy
  end

  def self.search(*args)
    client.search(*args)
  end

  def self.verify_user(requester_id)
    user(requester_id).verify
  end

  # @private
  #
  def self.client
    @@_client ||= ZendeskAPI::Client.new do |config|
      config.url      = ENV['ZENDESK_API_URL']
      config.username = "#{ENV['ZENDESK_USERNAME']}/token"
      config.password = ENV['ZENDESK_API_TOKEN']

      # Retry uses middleware to notify the user
      # when hitting the rate limit, sleep automatically,
      # then retry the request.
      config.retry = true

      # Logger prints to STDERR by default, to e.g. print to stdout:
      # require 'logger'
      # config.logger = Logger.new(STDOUT)
    end
  end

  # @private
  #
  def self.save_ticket_with_uploads!(ticket, uploads)
    uploads.each do |upload|
      ticket.comment.uploads << upload
    end

    ticket.save!
    Librato.increment 'support.new_ticket', source: 'zendesk'

    ticket
  end

  # @private
  #
  def self.extract_ticket_id_from_location(location)
    location[%r{/tickets/(\d+)\.json}, 1].to_i
  end

end
