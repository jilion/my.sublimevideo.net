class UserManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def create
    _transaction_with_graceful_fail do
      user.save!
      # UserMailer.delay(queue: 'my').welcome(user.id) # Temporary until we rewrite the email content
      NewsletterSubscriptionManager.delay(queue: 'my').sync_from_service(user.id)
      _increment_librato('create')
    end
  end

  %w[suspend unsuspend].each do |method_name|
    define_method(method_name) do
      _transaction_with_graceful_fail do
        user.send("#{method_name}!")
        send("_#{method_name}_all_sites")
        UserMailer.delay(queue: 'my').send("account_#{method_name}ed", user.id)
        _increment_librato(method_name)
      end
    end
  end

  def archive(options = {})
    { feedback: nil, skip_password: false }.merge!(options)

    _transaction_with_graceful_fail do
      _archive_site_and_save_feedback(options)

      NewsletterSubscriptionManager.delay(queue: 'my').unsubscribe(user.id)
      UserMailer.delay(queue: 'my').account_archived(user.id)
      _increment_librato('archive')
    end
  end

  private

  def _transaction_with_graceful_fail
    User.transaction do
      yield
    end
    true
  rescue => ex
    Rails.logger.info ex.inspect
    false
  end

  def _archive_site_and_save_feedback(options)
    _password_check! unless options.delete(:skip_password)
    user.archive!
    _archive_all_sites
    _revoke_all_oauth_tokens

    options[:feedback].save! if options[:feedback]
  end

  def _password_check!
    unless user.valid_password?(user.current_password)
      user.errors.add(:current_password, user.current_password.blank? ? :blank : :invalid)
      raise 'Current password needed!'
    end
  end

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

