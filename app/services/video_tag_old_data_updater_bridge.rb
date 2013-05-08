require 'video_tag_updater_worker'

class VideoTagOldDataUpdaterBridge
  attr_reader :site_token, :uid, :data

  def initialize(site_token, uid, data)
    @site_token = site_token
    @uid        = uid
    @data   = data
  end

  def update
    VideoTagUpdaterWorker.perform_async(site_token, uid, converted_data)
  end

  private

  def converted_data
    {}.tap do |hash|
      hash[:t] = data['n'] if title_from_attribute?
      %w[p i io d z uo].each do |attr|
        hash[attr.to_sym] = data[attr] if data[attr]
      end
    end
  end

  def title_from_attribute?
    data['no'] == 'a'
  end
end
