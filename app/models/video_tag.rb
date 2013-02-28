require 'sublime_video_private_api/model'
require 'rescue_me'

class VideoTag
  include SublimeVideoPrivateApi::Model
  uses_private_api :videos
  collection_path "/private_api/sites/:site_token/video_tags"

  def self.count(params = {})
    rescue_and_retry(3) do
      get_raw(:count, params)[:data][:count].to_i
    end
  end

  def self.backbone_attributes
    [:uid, :uid_origin, :title, :poster_url, :sources_id, :sources_origin]
  end

  def backbone_data
    attributes.slice(*self.class.backbone_attributes)
  end

  def to_param
    uid
  end

  def self.find(*args)
    super(*args)
  rescue URI::InvalidURIError => ex
    raise ActiveRecord::RecordNotFound, ex
  end
end
