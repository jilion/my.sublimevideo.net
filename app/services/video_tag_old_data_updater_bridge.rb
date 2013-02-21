require 'active_support/core_ext'
require 'video_tag_updater_worker'

class VideoTagOldDataUpdaterBridge
  attr_reader :site_token, :uid, :old_data

  def initialize(site_token, uid, old_data)
    @site_token = site_token
    @uid        = uid
    @old_data   = old_data
  end

  def update
    if uid_from_attribute?
      VideoTagUpdaterWorker.perform_async(site_token, uid, converted_data)
    end
  end

  private

  def converted_data
    {}.tap do |hash|
      hash[:t] = old_data['n'] if title_from_attribute?
      hash[:s] = sources if old_data['cs']
      %w[p i io d z uo].each do |attr|
        hash[attr.to_sym] = old_data[attr] if old_data[attr].present?
      end
    end
  end

  def uid_from_attribute?
    old_data['uo'] == 'a'
  end

  def title_from_attribute?
    old_data['no'] == 'a'
  end

  def sources
    old_data['cs'].map do |source_crc32|
      old_data['s'][source_crc32].symbolize_keys
    end
  end
end
