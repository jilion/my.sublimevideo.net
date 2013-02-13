
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

    def update(user_id, params = {})
      new(User.find(user_id)).update(params)
    end

    # Subscribes the given users to the newsletter
    #
    # users must respond to id, email, name and beta? (only the id is actually required)
    def import(users)
      users_to_import = users.inject([]) do |memo, user|
        memo << { id: user.id, email: user.email, name: user.name, beta: user.beta?.to_s }
      end
      CampaignMonitorWrapper.delay.import(
        list_id: list['list_id'],
        segment: list['segment'],
        users: users_to_import
      )
    end

    def sync_from_service(user_id)
      user = User.find(user_id)
      return if user.newsletter?

      CampaignMonitorWrapper.lists.each do |name, list|
        return user.update_column(:newsletter, true) if CampaignMonitorWrapper.subscriber(user.email, list['list_id'])
      end
    end

    def list
      CampaignMonitorWrapper.lists['sublimevideo']
    end

  end

  # Subscribes the given user to the newsletter
  #
  # user must respond to id, email, name and beta? (only the id is actually required)
  def subscribe
    CampaignMonitorWrapper.subscribe(
      list_id: self.class.list['list_id'],
      segment: self.class.list['segment'],
      user: { id: user.id, email: user.email, name: user.name, beta: user.beta?.to_s }
    )
  end

  # Unsubscribes the given user to the newsletter
  #
  # user must respond to email
  def unsubscribe
    CampaignMonitorWrapper.unsubscribe(
      list_id: self.class.list['list_id'],
      email: user.email
    )
  end

  def update(params)
    CampaignMonitorWrapper.update(params.merge(list_id: self.class.list['list_id']))
  end

end
