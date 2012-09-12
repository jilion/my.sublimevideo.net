# encoding: utf-8

class VideoTag
  include Mongoid::Document
  include Mongoid::Timestamps

  include VideoTagModules::Presenter
  include VideoTagModules::Scope

  field :st, type: String # Site token
  field :u,  type: String # Video uid
  # meta data
  field :uo, type: String # Video uid origin
  field :n,  type: String # Video name
  field :no, type: String # Video name origin
  field :p,  type: String # Video poster url
  field :z,  type: String # Player size
  field :cs, type: Array, default: [] # Video current sources array (cs) ['5062d010' (video source crc32), 'abcd1234', ... ] # sources actually used in the video tag
  field :s,  type: Hash,  default: {} # Video sources hash (s) { '5062d010' (video source crc32) => { u (source url) => 'http://.../dartmoor.mp4', q (quality) => 'hd', f (family) => 'mp4', r (resolution) => '320x240' }, ... }

  # NEW FIELDS
  field :d, type: Integer # Video duration (ms)
  field :state, type: String # State

  index st: 1, u: 1
  index st: 1, updated_at: 1
  # TODO Thibaud add indexes

  def site
    Site.find_by_token(st)
  end

  def to_param
    u
  end

  # ====================
  # = Instance Methods =
  # ====================

  def update_meta_data(meta_data)
    %w[uo n no p cs z].each do |key|
      self.send("#{key}=", meta_data[key]) if meta_data[key].present?
    end
    # Properly update sources
    self.s = read_attribute('s').merge(meta_data['s']) if meta_data['s'].present?

    changed = changed?
    self.updated_at = Time.now.utc # force updated_at update
    self.save
    changed
  end

  # meta_data is reserved in Mongoid
  def meta_data
    attributes.slice("uo", "n", "no", "p", "cs", "s", "z")
  end

  # =================
  # = Class Methods =
  # =================

  def self.find_by_st_and_u(st, u)
    where(st: st, u: u).first
  end

  def self.all_time_count(site_token)
    where(st: site_token).count
  end

  def self.last_30_days_updated_count(site_token)
    from = 30.days.ago.midnight.to_i
    where(st: site_token, updated_at: { :$gte => from }).count
  end

end
