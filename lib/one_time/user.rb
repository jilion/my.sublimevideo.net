module OneTime
  module User
    
    class << self
      # Method used in the 'one_time:delete_not_registered_invited_users' rake task
      def delete_invited_not_yet_registered_users
        ::User.invited.delete_all
      end
      
      # Method used in the 'one_time:set_remaining_discounted_months' rake task
      def set_remaining_discounted_months
        ::User.beta.update_all(:remaining_discounted_months => Billing.discounted_months)
      end
    end
    
  end
end