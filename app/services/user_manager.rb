class UserManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def create
    user.save!
    # UserMailer.delay.welcome(user.id) # Temporary until we rewrite the email content
    NewsletterSubscriptionManager.delay.sync_from_service(user.id)
    Librato.increment 'users.events', source: 'create'
    true
  rescue
    false
  end

  def suspend
    User.transaction do
      user.suspend!
      user.sites.active.map(&:suspend!)
    end
    UserMailer.delay.account_suspended(user.id)
    Librato.increment 'users.events', source: 'suspend'
    true
  rescue
    false
  end

  def unsuspend
    User.transaction do
      user.unsuspend!
      user.sites.suspended.map(&:unsuspend!)
    end
    UserMailer.delay.account_unsuspended(user.id)
    Librato.increment 'users.events', source: 'unsuspend'
    true
  rescue
    false
  end

  def archive(feedback = nil, skip_password = false)
    User.transaction do
      user.archived_at = Time.now.utc
      skip_password ? user.skip_password(:archive!) : user.archive!

      if feedback
        feedback.user_id = user.id
        feedback.save!
      end

      user.sites.not_archived.map(&:archive!)
      user.tokens.update_all(invalidated_at: Time.now.utc)
    end
    NewsletterSubscriptionManager.delay.unsubscribe(user.id)
    UserMailer.delay.account_archived(user.id)
    Librato.increment 'users.events', source: 'archive'
    true
  rescue
    false
  end
end

