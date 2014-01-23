module UsersTasks
  def self.update_campaign_monitor_billable_custom_field_for_all_active_users
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

  def self.cancel_failed_invoices_and_unsuspend_everyone
    puts "#{Invoice.where(state: 'failed').count} failed invoices will be canceled"unless Rails.env.test?
    Invoice.where(state: 'failed').update_all(state: 'canceled')
    failed_invoices_count = Invoice.where(state: 'failed').count
    puts "Failed invoices: #{failed_invoices_count}" unless Rails.env.test?
    return if failed_invoices_count > 0

    unsuspended = 0
    User.suspended.find_each do |user|
      UserManager.new(user).unsuspend
      unsuspended += 1
    end
    puts "#{unsuspended} users has been unsuspended" unless Rails.env.test?
  end

  private

  def self.campaign_monitor_import(users, custom_fields)
    users_to_import = users.reduce([]) do |a, user|
      a << { id: user.id, email: user.email, name: user.name }.merge(custom_fields)
    end
    CampaignMonitorWrapper.import(users_to_import)
  end
end
