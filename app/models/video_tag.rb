require 'sublime_video_private_api/model'

class VideoTag
  include SublimeVideoPrivateApi::Model
  uses_private_api :videos
  collection_path "/private_api/sites/:site_token/video_tags"

  def self.count(params = {})
    get_raw(:count, params)[:data][:count].to_i
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
end
