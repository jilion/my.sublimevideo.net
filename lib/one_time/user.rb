module OneTime
  module User

    class << self

      def update_campaign_monitor_billable_custom_field_for_all_active_users
        User.active.paying.find_in_batches(batch_size: 500) do |users|
          campaign_monitor_import(users, billable: true)
        end
        User.active.free.find_in_batches(batch_size: 500) do |users|
          campaign_monitor_import(users, billable: false)
        end
      end

      private

      def campaign_monitor_import(users, custom_fields)
        list = CampaignMonitorWrapper.lists['sublimevideo']
        users_to_import = users.inject([]) do |memo, user|
          memo << { id: user.id, email: user.email, name: user.name }.merge(custom_fields)
        end
        CampaignMonitorWrapper.import(
          list_id: list['list_id'],
          segment: list['segment'],
          users: users_to_import
        )
      end

    end

  end
end
