module OneTime
  module User

    class << self
      # Method used in the 'one_time:delete_not_registered_invited_users' rake task
      def archive_invited_not_yet_registered_users
        ::User.invited.each do |user|
          ::User.transaction do
            user.update_attribute(:state, 'archived')
            user.touch(:archived_at)
          end
        end
        ::User.invited.count.to_s
      end

      # Method used in the 'one_time:set_remaining_discounted_months' rake task
      def set_remaining_discounted_months
        ::User.beta.update_all(:remaining_discounted_months => Billing.discounted_months)
        ::User.beta.count.to_s
      end

      # Method used in the 'one_time:import_all_beta_users_to_campaign_monitor' rake task
      def import_all_beta_users_to_campaign_monitor
        ::User.beta.find_in_batches(:batch_size => 100) do |users|
          CampaignMonitor.import(users)
          puts "#{users.count} beta users imported to CampaignMonitor sublimevideo list"
        end
      end

    end

  end
end
