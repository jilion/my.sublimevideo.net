# coding: utf-8
require 'users_tasks'

namespace :users do
  desc "Update billable custom field on Campaign Monitor for all active users"
  task update_campaign_monitor_billable_custom_field_for_all_active_users: :environment do
    timed { UsersTasks.update_campaign_monitor_billable_custom_field_for_all_active_users }
  end
end