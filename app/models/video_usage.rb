# == Schema Information
#
# Table name: video_usages
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  log_id     :integer
#  started_at :datetime
#  ended_at   :datetime
#  bandwidth  :integer
#  created_at :datetime
#  updated_at :datetime
#

class VideoUsage < ActiveRecord::Base
  
  attr_accessible :video, :log, :bandwidth
  
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
  after_save        :update_video_bandwidth_cache
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_usages_from_trackers!(log, trackers)
    bandwidths = bandwidths_from(trackers)
    tokens     = tokens_from(bandwidths)
    while tokens.present?
      Video.where(:token => tokens.pop(100)).each do |video|
        create!(
          :video     => video,
          :log       => log,
          :bandwidth => bandwidths[video.token].to_i
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
  def update_video_bandwidth_cache
    video.increment(:bandwidth_cache, bandwidth)
  end
  
  # Compact trackers from RequestLogAnalyzer
  def self.bandwidths_from(trackers)
    trackers.inject({}) do |trackers, tracker|
      # case tracker.options[:title]
      # when :loader
      #   trackers[:loader] = tracker.categories.inject({}) do |tokens, (k,v)|
      #     if token = k.match(%r(/js/([a-z0-9]{8})\.js.*))[1]
      #       tokens.merge! token => v
      #     end
      #     tokens
      #   end
      # when :player
      #   trackers[:player] = tracker.categories.inject({}) do |tokens, (k,v)|
      #     if token = k.match(%r(/p/sublime\.js\?t=([a-z0-9]{8}).*))[1]
      #       tokens.merge! token => v
      #     end
      #     tokens
      #   end
      # when :flash
      #   trackers[:flash] = tracker.categories.inject({}) do |tokens, (k,v)|
      #     if token = k.match(%r(/p/sublime\.swf\?t=([a-z0-9]{8}).*))[1]
      #       tokens.merge! token => v
      #     end
      #     tokens
      #   end
      # end
      # trackers
    end
  end
  
  def self.tokens_from(bandwidths)
    bandwidths.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end
  
end