class CampaignMonitorWrapper
  include Configurator

  config_file 'campaign_monitor.yml'

  class << self

    def subscribe(params = {})
      custom_params = []
      custom_params << { Key: 'segment', Value: params[:segment] }
      custom_params << { Key: 'user_id', Value: params[:user][:id] }
      custom_params << { Key: 'beta',    Value: params[:user][:beta] } if params[:user] && params[:user][:beta]

      Librato.increment 'newsletter.subscribe', source: 'campaign_monitor'
      request do
        CreateSend::Subscriber.add(params[:list_id], params[:user][:email], params[:user][:name], custom_params, true)
      end
    end

    def import(params = {})
      subscribers = params[:users].inject([]) do |memo, user|
        custom_params = []
        custom_params << { Key: 'user_id',  Value: user[:id] }
        custom_params << { Key: 'segment',  Value: params[:segment] }
        custom_params << { Key: 'beta',     Value: user[:beta] } if user.key?(:beta)
        custom_params << { Key: 'billable', Value: user[:billable] } if user.key?(:billable)

        memo << { EmailAddress: user[:email], Name: user[:name], CustomFields: custom_params }
      end

      Librato.increment 'newsletter.import', source: 'campaign_monitor'
      request do
        CreateSend::Subscriber.import(params[:list_id], subscribers, false)
      end
    end

    def unsubscribe(params = {})
      Librato.increment 'newsletter.unsubscribe', source: 'campaign_monitor'
      request do
        CreateSend::Subscriber.new(params[:list_id], params[:email]).unsubscribe
        true
      end
    end

    def update(params = {})
      Librato.increment 'newsletter.update', source: 'campaign_monitor'
      request do
        if subscriber = CreateSend::Subscriber.new(params[:list_id], params[:email])
          subscriber.update(params[:user][:email], params[:user][:name], [], params[:user][:newsletter])
        end
      end
    end

    def subscriber(email, list_id = CampaignMonitorWrapper.lists['sublimevideo']['list_id'])
      Librato.increment 'newsletter.subscriber_lookup', source: 'campaign_monitor'
      request do
        CreateSend::Subscriber.get(list_id, email)
      end
    end

  private

    def set_api_key
      CreateSend.api_key(CampaignMonitorWrapper.api_key)
    end

    def request
      set_api_key
      yield
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      false
    end

    def log_bad_request(ex)
      Rails.logger.error "Campaign Monitor Bad request: #{ex}"
      Rails.logger.error "Error Code:    #{ex.data.Code}"
      Rails.logger.error "Error Message: #{ex.data.Message}"
    end

  end

end
