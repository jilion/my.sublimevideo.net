class CampaignMonitor < Settingslogic
  source "#{Rails.root}/config/campaign_monitor.yml"
  namespace Rails.env

  class << self

    def should_receive(*args)
      super
    end

    def subscribe(user)
      set_api_key
      CreateSend::Subscriber.add(
        self.list_id,
        user.email,
        user.full_name,
        [
          { :Key => 'user_id', :Value => user.id },
          { :Key => 'segment', :Value => self.segment }
        ],
        true
      )
    rescue CreateSend::BadRequest => br
      log_bad_request(br)
    end

    def import(users = [])
      set_api_key
      subscribers = users.collect do |user|
        {
          :EmailAddress => user.email,
          :Name => user.full_name,
          :CustomFields => [
            { :Key => 'user_id', :Value => user.id },
            { :Key => 'segment', :Value => self.segment }
          ]
        }
      end
      CreateSend::Subscriber.import(
        self.list_id,
        subscribers,
        false
      )
    rescue CreateSend::BadRequest => br
      log_bad_request(br)
    end

    def unsubscribe(email)
      subscriber = CreateSend::Subscriber.new(
        self.list_id,
        email
      )
      subscriber.unsubscribe
      true
    rescue CreateSend::BadRequest => br
      log_bad_request(br)
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

    def log_bad_request(br)
      Rails.logger.error "Campaign Monitor Bad request error: #{br}"
      Rails.logger.error "Error Code:    #{br.data.Code}"
      Rails.logger.error "Error Message: #{br.data.Message}"
    end

  end
end