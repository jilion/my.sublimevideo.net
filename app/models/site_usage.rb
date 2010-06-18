# == Schema Information
#
# Table name: site_usages
#
#  id          :integer         not null, primary key
#  site_id     :integer
#  log_id      :integer
#  started_at  :datetime
#  ended_at    :datetime
#  loader_hits :integer         default(0)
#  player_hits :integer         default(0)
#  flash_hits  :integer         default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

class SiteUsage < ActiveRecord::Base
  
  attr_accessible :site, :log, :loader_hits, :player_hits, :flash_hits
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :log
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :started_after, lambda { |date| where(:started_at.gteq => date) }
  scope :ended_before, lambda { |date| where(:ended_at.lt => date) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :site_id,      :presence => true
  validates :log_id,       :presence => true
  validates :started_at,   :presence => true
  validates :ended_at,     :presence => true
  validates :loader_hits,  :presence => true
  validates :player_hits,  :presence => true
  validates :flash_hits,   :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_dates_from_log, :on => :create
  after_save        :update_site_hits_cache
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_usages_from_trackers!(log, trackers)
    hits   = hits_from(trackers)
    tokens = tokens_from(hits)
    while tokens.present?
      Site.where(:token => tokens.pop(100)).each do |site|
        create!(
          :site         => site,
          :log          => log,
          :loader_hits  => hits[:loader][site.token].to_i,
          :player_hits  => hits[:player][site.token].to_i,
          :flash_hits   => hits[:flash][site.token].to_i
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
  def update_site_hits_cache
    Site.update_counters(
      site_id,
      :loader_hits_cache  => loader_hits,
      :player_hits_cache  => player_hits,
      :flash_hits_cache   => flash_hits
    )
  end
  
  # Compact trackers from RequestLogAnalyzer
  def self.hits_from(trackers)
    trackers.inject({}) do |trackers, tracker|
      trackers[tracker.options[:title]] = tracker.categories
      trackers
    end
  end
  
  def self.tokens_from(hits)
    hits.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end
  
end