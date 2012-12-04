module OneTime
  module User

    class << self

      def update_campaign_monitor_billable_custom_field_for_all_active_users
        imported = 0
        User.active.paying.find_in_batches(batch_size: 500) do |users|
          campaign_monitor_import(users, billable: true)
          imported += users.size
          puts "#{imported} users imported with billable custom field at true"
        end
        imported = 0
        User.active.free.find_in_batches(batch_size: 500) do |users|
          campaign_monitor_import(users, billable: false)
          imported += users.size
          puts "#{imported} users imported with billable custom field at false"
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
