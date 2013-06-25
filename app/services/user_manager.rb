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

  %w[suspend unsuspend].each do |method_name|
    define_method(method_name) do
      begin
        User.transaction do
          user.send("#{method_name}!")
          send("_#{method_name}_all_sites")
        end
        UserMailer.delay.send("account_#{method_name}ed", user.id)
        _increment_librato(method_name)

        true
      rescue
        false
      end
    end
  end

  def archive(options = {})
    { feedback: nil, skip_password: false }.merge!(options)

    _archive_site_and_save_feedback(options)

    NewsletterSubscriptionManager.delay.unsubscribe(user.id)
    UserMailer.delay.account_archived(user.id)
    _increment_librato('archive')

    true
  rescue
    false
  end

  private

  def _archive_site_and_save_feedback(options)
    User.transaction do
      _password_check! unless options.delete(:skip_password)
      user.archive!
      _archive_all_sites
      _revoke_all_oauth_tokens

      options[:feedback].save! if options[:feedback]
    end
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

