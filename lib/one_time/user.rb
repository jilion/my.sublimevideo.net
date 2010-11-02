module OneTime
  module User
    
    class << self
      # Method used in the 'one_time:delete_not_registered_invited_users' rake task
      def delete_invited_not_yet_registered_users
        ::User.invited.delete_all
      end
    end
    
  end
end