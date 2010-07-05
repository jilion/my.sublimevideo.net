# == Schema Information
#
# Table name: video_usages
#
#  id                :integer         not null, primary key
#  video_id          :integer
#  log_id            :integer
#  started_at        :datetime
#  ended_at          :datetime
#  hits              :integer         default(0)
#  bandwidth_s3      :integer         default(0)
#  bandwidth_us      :integer         default(0)
#  bandwidth_eu      :integer         default(0)
#  bandwidth_as      :integer         default(0)
#  bandwidth_jp      :integer         default(0)
#  bandwidth_unknown :integer         default(0)
#  requests_s3       :integer         default(0)
#  requests_us       :integer         default(0)
#  requests_eu       :integer         default(0)
#  requests_as       :integer         default(0)
#  requests_jp       :integer         default(0)
#  requests_unknown  :integer         default(0)
#  created_at        :datetime
#  updated_at        :datetime
#

class VideoUsage < ActiveRecord::Base
  
  attr_accessible :video, :log, :hits,
                  :bandwidth_s3, :bandwidth_us, :bandwidth_eu, :bandwidth_as, :bandwidth_jp, :bandwidth_unknown,
                  :requests_s3, :requests_us, :requests_eu, :requests_as, :requests_jp, :requests_unknown
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :video
  belongs_to :log
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :started_after, lambda { |date| where(:started_at.gteq => date) }
  scope :ended_before, lambda { |date| where(:ended_at.lt => date) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :video_id,          :presence => true
  validates :log_id,            :presence => true
  validates :started_at,        :presence => true
  validates :ended_at,          :presence => true
  validates :hits,              :presence => true
  validates :bandwidth_s3,      :presence => true
  validates :bandwidth_us,      :presence => true
  validates :bandwidth_eu,      :presence => true
  validates :bandwidth_as,      :presence => true
  validates :bandwidth_jp,      :presence => true
  validates :bandwidth_unknown, :presence => true
  validates :requests_s3,       :presence => true
  validates :requests_us,       :presence => true
  validates :requests_eu,       :presence => true
  validates :requests_as,       :presence => true
  validates :requests_jp,       :presence => true
  validates :requests_unknown,  :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_dates_from_log, :on => :create
  after_save        :update_video_hits_and_bandwidth_cache
  after_create      :notify_unknown_location
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_usages_from_trackers!(log, trackers)
    hbr    = hits_bandwidth_and_requests_from(trackers)
    tokens = tokens_from(hbr)
    while tokens.present?
      Video.where(:token => tokens.pop(100)).each do |video|
        create!(
          :video        => video,
          :log          => log,
          :hits         => (hits = hbr[:hits]) ? hits[video.token].to_i : 0,
          :bandwidth_s3 => (bandwidth = hbr[:bandwidth_s3]) ? bandwidth[video.token].to_i : 0,
          :bandwidth_us => (bandwidth = hbr[:bandwidth_us]) ? bandwidth[video.token].to_i : 0,
          :bandwidth_eu => (bandwidth = hbr[:bandwidth_eu]) ? bandwidth[video.token].to_i : 0,
          :bandwidth_as => (bandwidth = hbr[:bandwidth_as]) ? bandwidth[video.token].to_i : 0,
          :bandwidth_jp => (bandwidth = hbr[:bandwidth_jp]) ? bandwidth[video.token].to_i : 0,
          :bandwidth_unknown => (bandwidth = hbr[:bandwidth_unknown]) ? bandwidth[video.token].to_i : 0,
          :requests_s3  => (requests = hbr[:requests_s3]) ? requests[video.token].to_i : 0,
          :requests_us  => (requests = hbr[:requests_us]) ? requests[video.token].to_i : 0,
          :requests_eu  => (requests = hbr[:requests_eu]) ? requests[video.token].to_i : 0,
          :requests_as  => (requests = hbr[:requests_as]) ? requests[video.token].to_i : 0,
          :requests_jp  => (requests = hbr[:requests_jp]) ? requests[video.token].to_i : 0,
          :requests_unknown  => (requests = hbr[:requests_unknown]) ? requests[video.token].to_i : 0
        )
      end
    end
  end
  
private
  
  # before_validation
  def set_dates_from_log
    self.started_at ||= log.started_at
    self.ended_at   ||= log.ended_at
  end
  
  # after_save
  def update_video_hits_and_bandwidth_cache
    Video.update_counters(
      video_id,
      :hits_cache              => hits,
      :bandwidth_s3_cache      => bandwidth_s3,
      :bandwidth_us_cache      => bandwidth_us,
      :bandwidth_eu_cache      => bandwidth_eu,
      :bandwidth_as_cache      => bandwidth_as,
      :bandwidth_jp_cache      => bandwidth_jp,
      :bandwidth_unknown_cache => bandwidth_unknown,
      :requests_s3_cache       => requests_s3,
      :requests_us_cache       => requests_us,
      :requests_eu_cache       => requests_eu,
      :requests_as_cache       => requests_as,
      :requests_jp_cache       => requests_jp,
      :requests_unknown_cache  => requests_unknown
    )
  end
  
  # after_create
  def notify_unknown_location
    if bandwidth_unknown > 0 || requests_unknown > 0
       HoptoadNotifier.notify("VideoUsage (id #{id}, log_id #{log_id} contains unknown location")
    end
  end
  
  # Compact trackers from RequestLogAnalyzer
  def self.hits_bandwidth_and_requests_from(trackers)
    trackers.inject({}) do |trackers, tracker|
      trackers[tracker.options[:title]] = tracker.categories
      trackers
      case tracker.options[:title]
      when :hits, :requests_s3, :requests_us, :requests_eu, :requests_as, :requests_jp, :requests_unknown
        trackers[tracker.options[:title]] = tracker.categories
      when :bandwidth_s3
        trackers[:bandwidth_s3] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      when :bandwidth_us
        trackers[:bandwidth_us] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      when :bandwidth_eu
        trackers[:bandwidth_eu] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      when :bandwidth_as
        trackers[:bandwidth_as] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      when :bandwidth_jp
        trackers[:bandwidth_jp] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      when :bandwidth_unknown
        trackers[:bandwidth_unknown] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      end
      trackers
    end
  end
  
  def self.tokens_from(hits_bandwidth_and_requests)
    hits_bandwidth_and_requests.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end
  
end