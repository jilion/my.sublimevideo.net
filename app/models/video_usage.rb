# == Schema Information
#
# Table name: video_usages
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  log_id     :integer
#  started_at :datetime
#  ended_at   :datetime
#  hits       :integer         default(0)
#  bandwidth  :integer         default(0)
#  created_at :datetime
#  updated_at :datetime
#

class VideoUsage < ActiveRecord::Base
  
  attr_accessible :video, :log, :hits, :bandwidth
  
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
  
  validates :video_id,   :presence => true
  validates :log_id,     :presence => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  validates :bandwidth,  :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_dates_from_log, :on => :create
  after_save        :update_video_hits_and_bandwidth_cache
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_usages_from_trackers!(log, trackers)
    hits_and_bandwidths = hits_and_bandwidths_from(trackers)
    tokens              = tokens_from(hits_and_bandwidths)
    while tokens.present?
      Video.where(:token => tokens.pop(100)).each do |video|
        create!(
          :video     => video,
          :log       => log,
          :hits      => (hits = hits_and_bandwidths[:hits]) ? hits[video.token].to_i : 0,
          :bandwidth => hits_and_bandwidths[:bandwidth][video.token].to_i
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
      :hits_cache      => hits,
      :bandwidth_cache => bandwidth
    )
  end
  
  # Compact trackers from RequestLogAnalyzer
  def self.hits_and_bandwidths_from(trackers)
    trackers.inject({}) do |trackers, tracker|
      trackers[tracker.options[:title]] = tracker.categories
      trackers
      case tracker.options[:title]
      when :hits
        trackers[:hits] = tracker.categories
      when :bandwidth
        trackers[:bandwidth] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      end
      trackers
    end
  end
  
  def self.tokens_from(hits_and_bandwidths)
    hits_and_bandwidths.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end
  
end