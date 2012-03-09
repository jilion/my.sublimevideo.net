class LegacyStat::Video
  include Mongoid::Document
  include LegacyStat
  store_in :video_stats

  field :st, type: String # Site token
  field :u,  type: String # Video uid

  field :vl, type: Hash, default: {} # Video Loads: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
  field :vs, type: Hash, default: {} # Video Sources View { '5062d010' (video source crc32) => 32, ... }

  index :s
  index :m
  index :h
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

end
