require "zendesk/collection"

module Zendesk
  # Wrapper for the Zendesk REST API
  #
  # @note All methods have been separated into modules and follow the same grouping used in {the Zendesk API Documentation}.
  class Client < API
    # Require client method modules after initializing the Client class in
    # order to avoid a superclass mismatch error, allowing those modules to be
    # Client-namespaced.
    require "zendesk/client/users"
    require "zendesk/client/organizations"
    require "zendesk/client/groups"
    require "zendesk/client/tickets"
    require "zendesk/client/forums"
    require "zendesk/client/entries"
    require "zendesk/client/attachments"
    require "zendesk/client/tags"
    require "zendesk/client/ticket_fields"
    require "zendesk/client/macros"
    require "zendesk/client/search"

    include Zendesk::Client::Users
    include Zendesk::Client::Organizations
    include Zendesk::Client::Groups
    include Zendesk::Client::Tickets
    include Zendesk::Client::Forums
    include Zendesk::Client::Entries
    include Zendesk::Client::Attachments
    include Zendesk::Client::Tags
    include Zendesk::Client::Search
    include Zendesk::Client::TicketFields
    include Zendesk::Client::Macros
  end
end
