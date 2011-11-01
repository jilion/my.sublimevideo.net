class VideoTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :st, :type => String # Site token
  field :u,  :type => String # Video uid

  field :uo, :type => String # Video uid origin
  field :n,  :type => String # Video name
  field :no, :type => String # Video name origin
  field :p,  :type => String # Video poster url
  field :cs, :type => Array  # Video current sources array (cs) ['5062d010' (video source crc32), 'abcd1234', ... ] # sources actually used in the video tag
  field :s,  :type => Hash   # Video sources hash (s) { '5062d010' (video source crc32) => { u (source url) => 'http://.../dartmoor.mp4', q (quality) => 'hd', f (family) => 'mp4', r (resolution) => '320x240', ua (updated_at) => date }, ... }

  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING]]

  def site
    Site.find_by_token(st)
  end

  # ====================
  # = Instance Methods =
  # ====================
  
  # =================
  # = Class Methods =
  # =================
  
  def self.update_video_tags_from_trackers!(trackers)
    video_tags = video_tags_from_trackers(trackers)
  end
  
private


  # Merge each videos tag in one big hash
  #
  # { ['site_token','video_uid'] => { uo: ..., n: ..., cs: ['5062d010',...], s: { '5062d010' => { ...}, ... } } }
  #
  def self.video_tags_from_trackers(trackers)
    trackers   = only_video_tags_trackers(trackers)
    video_tags = {}
    trackers.each do |request, hits|
      params = Addressable::URI.parse(request).query_values.try(:symbolize_keys) || {}
      p params
    end
    video_tags
  end
  
  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :video_tags }.categories
  end
  
end
