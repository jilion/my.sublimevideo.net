require_dependency 'campaign_monitor/campaign_monitor_config'

class CampaignMonitorWrapper

  class << self

    def subscribe(params = {})
      custom_params = []
      custom_params << { Key: 'segment', Value: params[:segment] }
      custom_params << { Key: 'user_id', Value: params[:user][:id] }
      custom_params << { Key: 'beta',    Value: params[:user][:beta] } if params[:user] && params[:user][:beta]

      request do
        CreateSend::Subscriber.add(params[:list_id], params[:user][:email], params[:user][:name], custom_params, true)
      end
    end

    def import(params = {})
      subscribers = params[:users].inject([]) do |memo, user|
        custom_params = []
        custom_params << { Key: 'segment', Value: params[:segment] }
        custom_params << { Key: 'user_id', Value: user[:id] }
        custom_params << { Key: 'beta',    Value: user[:beta] }

        memo << { EmailAddress: user[:email], Name: user[:name], CustomFields: custom_params }
      end

      request do
        CreateSend::Subscriber.import(params[:list_id], subscribers, false)
      end
    end

    def unsubscribe(params = {})
      request do
        CreateSend::Subscriber.new(params[:list_id], params[:email]).unsubscribe
        true
      end
    end

    def update(params = {})
      request do
        if subscriber = CreateSend::Subscriber.new(params[:list_id], params[:email])
          subscriber.update(params[:user][:email], params[:user][:name], [], params[:user][:newsletter])
        end
      end
    end

    def subscriber(email, list_id = CampaignMonitorConfig.lists.sublimevideo.list_id)
      request do
        CreateSend::Subscriber.get(list_id, email)
      end
    end

  private

    def set_api_key
      CreateSend.api_key(CampaignMonitorConfig.api_key)
    end

    def request
      set_api_key
      yield
    rescue CreateSend::BadRequest => ex
      log_bad_request(ex)
      false
    end

    def log_bad_request(ex)
      Rails.logger.error "Campaign Monitor Bad request error: #{ex}"
      Rails.logger.error "Error Code:    #{ex.data.Code}"
      Rails.logger.error "Error Message: #{ex.data.Message}"
    end

  end

end
