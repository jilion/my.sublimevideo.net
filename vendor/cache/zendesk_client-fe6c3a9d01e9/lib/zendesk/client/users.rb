module Zendesk
  class Client
    module Users
      # @zendesk.users                               - a list of users (limit 15)
      # @zendesk.users.per_page(100)                 - a list of users (limit 15)
      # @zendesk.users(123)                          - the user with id=123
      # @zendesk.users("Bob")                        - users with name matching all or part of "Bob"
      # @zendesk.users("Bob", :role => :end_user)    - users with name matching all or part of "Bob"
      def users(*args)
        UsersCollection.new(self, *args)
      end
    end

    class UsersCollection < Collection
      def initialize(client, *args)
        super(client, :user, *args)
      end

      # ## Get currently authenticated user
      #
      #    @zendesk.users.current
      #
      def current
        @query[:path] += "/current"
        self
      end
      alias me current

      # ## Get a user's identities (email addresses, twitter handles, etc)
      #
      #    @zendesk.users(123).identities
      #
      def identities(id=nil)
        @query[:path] += "/user_identities/#{id}"
        self
      end
    end
  end
end
