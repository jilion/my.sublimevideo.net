require_dependency 'service/newsletter'

module Service
  User = Struct.new(:user) do
    def create
      ::User.transaction do
        user.save!

        UserMailer.delay.welcome(user.id)
        Service::Newsletter.delay.sync_from_service(user.id)
      end
    rescue
      false
    end

    def suspend
      ::User.transaction do
        user.suspend!

        user.sites.active.map(&:suspend!)

        UserMailer.delay.account_suspended(user.id)
      end
    rescue
      false
    end

    def unsuspend
      ::User.transaction do
        user.unsuspend!

        user.sites.suspended.map(&:unsuspend!)

        UserMailer.delay.account_unsuspended(user.id)
      end
    rescue
      false
    end

    def archive(feedback = nil)
      ::User.transaction do
        user.archived_at = Time.now.utc
        user.archive!

        if feedback
          feedback.user_id = user.id
          feedback.save!
        end

        user.sites.map(&:archive!)

        user.tokens.update_all(invalidated_at: Time.now.utc)

        Service::Newsletter.delay.unsubscribe(user.id)
        UserMailer.delay.account_archived(user.id)
      end
    rescue
      false
    end
  end
end
