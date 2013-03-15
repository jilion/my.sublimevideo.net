class UserManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def create
    user.save!
    # UserMailer.delay.welcome(user.id) # Temporary until we rewrite the email content
    NewsletterSubscriptionManager.delay.sync_from_service(user.id)
    _increment_librato('create')

    true
  rescue
    false
  end

  def suspend
    User.transaction do
      user.suspend!
      _suspend_all_sites
    end
    UserMailer.delay.account_suspended(user.id)
    _increment_librato('suspend')

    true
  rescue
    false
  end

  def unsuspend
    User.transaction do
      user.unsuspend!
      _unsuspend_all_sites
    end
    UserMailer.delay.account_unsuspended(user.id)
    _increment_librato('unsuspend')

    true
  rescue
    false
  end

  def archive(options = {})
    { feedback: nil, skip_password: false }.merge!(options)

    User.transaction do
      options[:skip_password] ? user.skip_password(:archive!) : user.archive!

      options[:feedback].save! if options[:feedback]

      _archive_all_sites
      _revoke_all_oauth_tokens
    end
    NewsletterSubscriptionManager.delay.unsubscribe(user.id)
    UserMailer.delay.account_archived(user.id)
    _increment_librato('archive')

    true
  rescue => ex
    puts ex
    false
  end

  private

  def _suspend_all_sites
    user.sites.active.map(&:suspend!)
  end

  def _unsuspend_all_sites
    user.sites.suspended.map(&:unsuspend!)
  end

  def _archive_all_sites
    user.sites.not_archived.map(&:archive!)
  end

  def _revoke_all_oauth_tokens
    user.tokens.update_all(invalidated_at: Time.now.utc)
  end

  def _increment_librato(source)
    Librato.increment 'users.events', source: source
  end
end

