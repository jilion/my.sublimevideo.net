class NewInactiveUserNotifier

  def self.send_emails
   inactive_users do |user|
      UserMailer.delay(queue: 'my-mailer').inactive_account(user.id)
    end
  end

  private

  def self.inactive_users
    User.active.created_on(1.week.ago).find_each do |user|
      starts = user.sites.not_archived.sum(:last_30_days_admin_starts)
      yield(user) if starts.zero?
    end
  end
end
