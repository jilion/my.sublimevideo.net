class SiteUsage
  include Mongoid::Document

  field :site_id,         type: Integer
  field :day,             type: DateTime

  field :loader_hits,                type: Integer, default: 0 # ssl included
  field :ssl_loader_hits,            type: Integer, default: 0
  field :player_hits,                type: Integer, default: 0
  field :main_player_hits,           type: Integer, default: 0 # non-cached
  field :main_player_hits_cached,    type: Integer, default: 0
  field :extra_player_hits,          type: Integer, default: 0 # non-cached
  field :extra_player_hits_cached,   type: Integer, default: 0
  field :dev_player_hits,            type: Integer, default: 0 # non-cached
  field :dev_player_hits_cached,     type: Integer, default: 0
  field :invalid_player_hits,        type: Integer, default: 0 # non-cached
  field :invalid_player_hits_cached, type: Integer, default: 0
  field :flash_hits,                 type: Integer, default: 0
  field :requests_s3,                type: Integer, default: 0
  field :traffic_s3,                 type: Integer, default: 0
  field :traffic_voxcast,            type: Integer, default: 0

  index site_id: 1
  index site_id: 1, day: 1 #, unique: true

  acts_as_api
  api_accessible :v1_self_private do |template|
    template.add lambda { |usage| usage.day.strftime("%Y-%m-%d") }, as: :day
    template.add lambda { |usage| usage.billable_player_hits }, as: :video_views
  end

  def site
    Site.find_by_id(site_id)
  end

  def billable_player_hits
    main_player_hits.to_i + main_player_hits_cached.to_i + extra_player_hits.to_i + extra_player_hits_cached.to_i
  end
end
