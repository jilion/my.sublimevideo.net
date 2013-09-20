class NewInactiveUserNotifier

  def self.send_emails
   inative_users do |user|
      UserMailer.delay(queue: 'my-mailer').inactive_account(user.id)
    end
  end

  private

  def self.inative_users
    User.active.created_on(1.week.ago).find_each do |user|
      site_tokens = user.sites.not_archived.map(&:token)
      page_visits = Stat::Site::Day.all_time_page_visits(site_tokens)
      yield(user) if page_visits.zero?
    end
  end
end
