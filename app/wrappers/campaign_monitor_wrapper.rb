require 'configurator'

class CampaignMonitorWrapper
  include Configurator

  config_file 'campaign_monitor.yml'
  config_accessor :api_key, :lists

  def initialize
    CreateSend.api_key(CampaignMonitorWrapper.api_key)
  end

  def subscribe(params = {})
    custom_params = self.class._build_custom_params(segment: params[:segment], user_id: params[:user][:id], beta: params[:user][:beta], billable: params[:user][:billable])

    _request('subscribe') do
      CreateSend::Subscriber.add(params[:list_id], params[:user][:email], params[:user][:name], custom_params, true)
    end
  end

  def import(params = {})
    subscribers = params[:users].reduce([]) do |memo, user|
      custom_params = self.class._build_custom_params(segment: params[:segment], user_id: user[:id], beta: user[:beta], billable: user[:billable])

      memo << { EmailAddress: user[:email], Name: user[:name], CustomFields: custom_params }
    end

    _request('import') do
      CreateSend::Subscriber.import(params[:list_id], subscribers, false)
    end
  end

  def unsubscribe(params = {})
    _request('unsubscribe') do
      CreateSend::Subscriber.new(params[:list_id], params[:email]).unsubscribe
      true
    end
  end

  def update(params = {})
    _request('update') do
      if subscriber = CreateSend::Subscriber.new(params[:list_id], params[:email])
        subscriber.update(params[:user][:email], params[:user][:name], [], params[:user][:newsletter])
      end
    end
  end

  def subscriber(email, list_id = CampaignMonitorWrapper.lists['sublimevideo']['list_id'])
    _request('subscriber_lookup') do
      CreateSend::Subscriber.get(list_id, email)
    end
  end

  private

  def _request(method)
    result = yield
    self.class._increment_librato(method)
    result
  rescue CreateSend::BadRequest => ex
    self.class._log_bad_request(ex)
    false
  end

  class << self

    %w[subscribe import unsubscribe update subscriber].each do |method_name|
      define_method method_name do |*args|
        new.send(method_name, *args)
      end
    end

    def _build_custom_params(hash)
      custom_params = []
      hash.map do |k, v|
        { Key: k.to_s, Value: v }
      end
    end

    def _log_bad_request(ex)
      Rails.logger.error "Campaign Monitor Bad request: #{ex}"
      Rails.logger.error "Error Code:    #{ex.data.Code}"
      Rails.logger.error "Error Message: #{ex.data.Message}"
    end

    def _increment_librato(method)
      Librato.increment "newsletter.#{method}", source: 'campaign_monitor'
    end

  end

end
