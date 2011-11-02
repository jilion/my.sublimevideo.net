class Stat::Video
  include Mongoid::Document
  include Stat
  store_in :video_stats

  field :st, type: String # Site token
  field :u,  type: String # Video uid

  field :vl, type: Hash, default: {} # Video Loads: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}
  field :vs, type: Hash, default: {} # Video Sources View { '5062d010' (video source crc32) => 32, ... }

  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

  def site
    Site.find_by_token(st)
  end

  # ====================
  # = Instance Methods =
  # ====================

  def site_token
    read_attribute(:st)
  end


end
