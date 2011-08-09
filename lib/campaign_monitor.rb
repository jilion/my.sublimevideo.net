class CampaignMonitor < Settingslogic
  source "#{Rails.root}/config/campaign_monitor.yml"
  namespace Rails.env

  class << self

    def subscribe(user)
      set_api_key
      CreateSend::Subscriber.add(self.list_id, user.email, user.full_name,
        [
          { :Key => 'user_id', :Value => user.id },
          { :Key => 'segment', :Value => self.segment },
          { :Key => 'beta',    :Value => user.beta?.to_s }
        ],
        true
      )
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
    end

    def import(users=[])
      set_api_key
      subscribers = users.collect do |user|
        {
          :EmailAddress => user.email,
          :Name => user.full_name,
          :CustomFields => [
            { :Key => 'user_id', :Value => user.id },
            { :Key => 'segment', :Value => self.segment },
            { :Key => 'beta',    :Value => user.beta?.to_s }
          ]
        }
      end
      CreateSend::Subscriber.import(self.list_id, subscribers, false)
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
    end

    def unsubscribe(email)
      set_api_key
      CreateSend::Subscriber.new(self.list_id, email).unsubscribe
      true
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      false
    end

    def state(email)
      if subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, email)
        subscriber["State"]
      end
    rescue
      "Unknown"
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