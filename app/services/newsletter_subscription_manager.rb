class NewsletterSubscriptionManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  class << self

    def subscribe(user_id)
      new(User.find(user_id)).subscribe
    end

    def unsubscribe(user_id)
      new(User.find(user_id)).unsubscribe
    end

    def update(user_id, old_email)
      new(User.find(user_id)).update(old_email)
    end

    # Subscribes the given users to the newsletter
    #
    # users must respond to id, email, name and beta? (only the id is actually required)
    def import(users)
      users_to_import = users.reduce([]) do |a, user|
        a << { id: user.id, email: user.email, name: user.name, beta: user.beta?.to_s, billable: user.billable?.to_s }
      end
      CampaignMonitorWrapper.delay.import(users_to_import)
    end

    def sync_from_service(user_id)
      user = User.find(user_id)

      if !user.newsletter? && CampaignMonitorWrapper.subscriber(user.email)
        user.update_column(:newsletter, true)
      end
    end

  end

  # Subscribes the given user to the newsletter
  #
  # user must respond to id, email, name and beta? (only the id is actually required)
  def subscribe
    CampaignMonitorWrapper.subscribe(id: user.id, email: user.email, name: user.name, beta: user.beta?.to_s, billable: user.billable?.to_s)
  end

  # Unsubscribes the given user to the newsletter
  #
  # user must respond to email
  def unsubscribe
    CampaignMonitorWrapper.unsubscribe(user.email)
  end

  def update(old_email)
    CampaignMonitorWrapper.update(old_email: old_email, email: user.email, name: user.name, newsletter: user.newsletter?)
  end

end
