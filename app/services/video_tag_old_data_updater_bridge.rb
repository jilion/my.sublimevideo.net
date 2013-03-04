require 'video_tag_updater_worker'

class VideoTagOldDataUpdaterBridge
  attr_reader :site_token, :uid, :data

  def initialize(site_token, uid, data)
    @site_token = site_token
    @uid        = uid
    @data   = data
  end

  def update
    if uid_from_attribute? || first_source_present? || sources_id_present?
      VideoTagUpdaterWorker.perform_async(site_token, uid, converted_data)
    end
  end

  private

  def converted_data
    {}.tap do |hash|
      hash[:t] = data['n'] if title_from_attribute?
      hash[:s] = converted_sources if first_source_present?
      %w[p i io d z uo].each do |attr|
        hash[attr.to_sym] = data[attr] if data[attr]
      end
    end
  end

  def converted_sources
    [data['s'][data['cs'].first]]
  end

  def uid_from_attribute?
    data['uo'] == 'a'
  end

  def title_from_attribute?
    data['no'] == 'a'
  end

  def first_source_present?
    data['cs'].is_a?(Array) && data['cs'].first && data['s'][data['cs'].first]
  end

  def sources_id_present?
    data['i'] && data['io']
  end
end
