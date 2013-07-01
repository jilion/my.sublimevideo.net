require 'createsend'
require 'rescue_me'

class CampaignMonitorWrapper

  LIST = {
    'development' => {
      list_id: 'a064dfc4b8ccd774252a2e9c9deb9244',
      segment: 'dev'
    },
    'test' => {
      list_id: 'a064dfc4b8ccd774252a2e9c9deb9244',
      segment: 'test'
    },
    'staging' => {
      list_id: 'a064dfc4b8ccd774252a2e9c9deb9244',
      segment: 'staging'
    },
    'production' => {
      list_id: '1defd3a2fa342e3534126166f32e02d2',
      segment: 'my.sublimevideo.net'
    }
  }

  def self.list
    @@list ||= LIST[Rails.env]
  end

  class << self

    %w[subscribe import unsubscribe update subscriber].each do |method_name|
      define_method method_name do |*args|
        new.send(method_name, *args)
      end
    end

  end

  def initialize
    CreateSend.api_key(ENV['CAMPAIGN_MONITOR_API_KEY'])
  end

  def subscribe(params = {})
    custom_params = _build_custom_params(segment: self.class.list[:segment], user_id: params[:id], beta: params[:beta], billable: params[:billable])

    _request('subscribe') do
      CreateSend::Subscriber.add(self.class.list[:list_id], params[:email], params[:name], custom_params, true)
    end
  end

  def import(users = {})
    subscribers = users.reduce([]) do |memo, user|
      custom_params = _build_custom_params(segment: self.class.list[:segment], user_id: user[:id], beta: user[:beta], billable: user[:billable])

      memo << { EmailAddress: user[:email], Name: user[:name], CustomFields: custom_params }
    end

    _request('import') do
      CreateSend::Subscriber.import(self.class.list[:list_id], subscribers, false)
    end
  end

  def unsubscribe(email)
    _request('unsubscribe') do
      CreateSend::Subscriber.new(self.class.list[:list_id], email).unsubscribe
      true
    end
  end

  def update(params = {})
    _request('update') do
      if subscriber = CreateSend::Subscriber.new(self.class.list[:list_id], params.delete(:old_email))
        subscriber.update(params[:email], params[:name], [], params[:newsletter])
      end
    end
  end

  def subscriber(email)
    _request('subscriber_lookup') do
      CreateSend::Subscriber.get(self.class.list[:list_id], email)
    end
  end

  private

  def _request(method)
    result = _with_rescue_and_retry(7) do
      yield
    end
    _increment_librato(method)
    result
  rescue CreateSend::BadRequest => ex
    _log_bad_request(ex)
    false
  end

  def _with_rescue_and_retry(times)
    rescue_and_retry(times, CreateSend::Unauthorized) do
      yield
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
