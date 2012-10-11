require_dependency 'service/newsletter'

module Service
  User = Struct.new(:user) do

    class << self

      def build(params)
        new ::User.new(params)
      end

    end

    def initial_save
      ::User.transaction do
        user.save && send_welcome_email && sync_with_newsletter_service
      end
    end

    def suspend
      ::User.transaction do
        user.suspend && suspend_active_sites && send_account_suspended_email
      end
    end

    def unsuspend
      ::User.transaction do
        user.unsuspend && unsuspend_suspended_sites && send_account_unsuspended_email
      end
    end

    def archive
      ::User.transaction do
        user.archive && send_account_archived_email
      end
    end

    private

    def send_welcome_email
      UserMailer.delay.welcome(user.id)
    end

    def sync_with_newsletter_service
      Service::Newsletter.delay.sync_from_service(user.id)
    end

    def suspend_active_sites
      user.sites.active.map(&:suspend)
    end

    def send_account_suspended_email
      UserMailer.delay.account_suspended(user.id)
    end

    def unsuspend_suspended_sites
      user.sites.suspended.map(&:unsuspend)
    end

    def send_account_unsuspended_email
      UserMailer.delay.account_unsuspended(user.id)
    end

    def send_account_archived_email
      UserMailer.delay.account_archived(user.id)
    end

  end
end
