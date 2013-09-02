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

  def self.auth
    @@auth ||= { api_key: ENV['CAMPAIGN_MONITOR_API_KEY'] }
  end

  def self.list
    @@list ||= LIST[Rails.env]
  end

  def self.subscribe(params = {})
    _request('subscribe') do
      CreateSend::Subscriber.add(self.auth, self.list[:list_id], params[:email], params[:name], _user_params_from_hash(params), true)
    end
  end

  def self.import(users = {})
    subscribers = users.reduce([]) do |memo, user|
      memo << { EmailAddress: user[:email], Name: user[:name], CustomFields: _user_params_from_hash(user) }
    end

    _request('import') do
      CreateSend::Subscriber.import(self.auth, self.list[:list_id], subscribers, false)
    end
  end

  def self.unsubscribe(email)
    _request('unsubscribe') do
      CreateSend::Subscriber.new(self.auth, self.list[:list_id], email).unsubscribe
      true
    end
  end

  def self.update(params = {})
    _request('update') do
      if subscriber = CreateSend::Subscriber.new(self.auth, self.list[:list_id], params.delete(:old_email))
        subscriber.update(params[:email], params[:name], [], params[:newsletter])
      end
    end
  end

  def self.subscriber(email)
    _request('subscriber_lookup') do
      CreateSend::Subscriber.get(self.auth, self.list[:list_id], email)
    end
  end

  private

  def self._request(method)
    result = _with_rescue_and_retry(7) do
      yield
    end
    _increment_librato(method)
    result
  rescue CreateSend::BadRequest => ex
    _log_bad_request(ex)
    false
  end

  def self._with_rescue_and_retry(times)
    rescue_and_retry(times, CreateSend::Unauthorized) do
      yield
    end
  end

  def self._params_for_api(hash)
    custom_params = []
    hash.map do |k, v|
      { Key: k.to_s, Value: v }
    end
  end

  def self._user_params_from_hash(hash)
    _params_for_api(segment: self.list[:segment], user_id: hash[:id], beta: hash[:beta], billable: hash[:billable])
  end

  def self._log_bad_request(ex)
    Rails.logger.error "Campaign Monitor Bad request: #{ex}"
    Rails.logger.error "Error Code:    #{ex.data.Code}"
    Rails.logger.error "Error Message: #{ex.data.Message}"
  end

  def self._increment_librato(method)
    Librato.increment "newsletter.#{method}", source: 'campaign_monitor'
  end

end
