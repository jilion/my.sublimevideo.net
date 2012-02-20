class CampaignMonitor < Settingslogic
  source "#{Rails.root}/config/campaign_monitor.yml"
  namespace Rails.env

  class << self

    def subscribe(user)
      set_api_key
      CreateSend::Subscriber.add(self.lists.sublimevideo.list_id, user.email, user.name,
        [
          { Key: 'user_id', Value: user.id },
          { Key: 'segment', Value: self.lists.sublimevideo.segment },
          { Key: 'beta',    Value: user.beta?.to_s }
        ],
        true
      )
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
    end

    def import(users = [])
      set_api_key
      subscribers = users.collect do |user|
        {
          EmailAddress: user.email,
          Name: user.name,
          CustomFields: [
            { Key: 'user_id', Value: user.id },
            { Key: 'segment', Value: self.lists.sublimevideo.segment },
            { Key: 'beta',    Value: user.beta?.to_s }
          ]
        }
      end
      CreateSend::Subscriber.import(self.lists.sublimevideo.list_id, subscribers, false)
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
    end

    def unsubscribe(email)
      set_api_key
      CreateSend::Subscriber.new(self.lists.sublimevideo.list_id, email).unsubscribe
      true
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      false
    end

    def update(user)
      set_api_key
      if subscriber = CreateSend::Subscriber.new(self.lists.sublimevideo.list_id, user.email_was.presence || user.email)
        subscriber.update(user.email, user.name, [], user.newsletter?)
      end
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      false
    end

    def subscriber(email, list_id=self.lists.sublimevideo.list_id)
      set_api_key
      if subscriber = CreateSend::Subscriber.get(list_id, email)
        subscriber
      else
        nil
      end
    rescue CreateSend::NotFound => ex
      nil
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      nil
    end

  private

    def set_api_key
      CreateSend.api_key self.api_key
    end

    def log_bad_request(ex)
      Rails.logger.error "Campaign Monitor Bad request error: #{ex}"
      Rails.logger.error "Error Code:    #{ex.data.Code}"
      Rails.logger.error "Error Message: #{ex.data.Message}"
    end

  end
end
