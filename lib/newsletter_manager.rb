require_dependency 'campaign_monitor/campaign_monitor_config'
require_dependency 'campaign_monitor/campaign_monitor_wrapper'

class NewsletterManager

  class << self

    # Subscribes the given user to the newsletter
    #
    # user must respond to id, email, name and beta? (only the id is actually required)
    def subscribe(user)
      CampaignMonitorWrapper.delay.subscribe(
        list_id: list['list_id'],
        segment: list['segment'],
        user: { id: user.id, email: user.email, name: user.name, beta: user.beta?.to_s }
      )
    end

    # Unsubscribes the given user to the newsletter
    #
    # user must respond to email
    def unsubscribe(user)
      CampaignMonitorWrapper.delay.unsubscribe(
        list_id: list['list_id'],
        email: user.email
      )
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

    def update(user)
      CampaignMonitorWrapper.delay.update(
        email: user.email_was || user.email,
        user: { email: user.email, name: user.name, newsletter: user.newsletter? }
      )
    end

    def sync_from_service(user)
      self.delay._sync_from_service(user.id)
    end

  private

    def _sync_from_service(user_id)
      user = User.find(user_id)

      CampaignMonitorConfig.lists.each do |name, list|
        return user.update_column(:newsletter, true) if CampaignMonitorWrapper.subscriber(user.email, list['list_id'])
      end
    end

    def list
      @list ||= CampaignMonitorConfig.lists['sublimevideo']
    end

  end

end
