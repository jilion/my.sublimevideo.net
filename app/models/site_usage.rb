class SiteUsage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :site_id,         :type => Integer
  field :started_at,      :type => DateTime
  field :ended_at,        :type => DateTime
  field :loader_hits,     :type => Integer, :default => 0
  
  field :player_hits,                :type => Integer, :default => 0
  field :main_player_hits,           :type => Integer, :default => 0
  field :main_player_hits_cached,    :type => Integer, :default => 0
  field :dev_player_hits,            :type => Integer, :default => 0
  field :dev_player_hits_cached,     :type => Integer, :default => 0
  field :invalid_player_hits,        :type => Integer, :default => 0
  field :invalid_player_hits_cached, :type => Integer, :default => 0
  
  field :flash_hits,      :type => Integer, :default => 0
  field :requests_s3,     :type => Integer, :default => 0
  field :traffic_s3,      :type => Integer, :default => 0
  field :traffic_voxcast, :type => Integer, :default => 0
  
  index :site_id
  index :started_at
  index :ended_at
  
  attr_accessible :site, :log, :loader_hits, :flash_hits, :requests_s3, :traffic_s3, :traffic_voxcast, :player_hits,
                  :main_player_hits, :main_player_hits_cached, :dev_player_hits, :dev_player_hits_cached,
                  :invalid_player_hits, :invalid_player_hits_cached
  
  # ================
  # = Associations =
  # ================
  
  def site
    Site.find_by_id(site_id)
  end
  def site=(site)
    self.site_id = site.id
  end
  
  referenced_in :log, :index => true
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :started_after, lambda { |date| where(:started_at => { "$gte" => date }) }
  scope :ended_before,  lambda { |date| where(:ended_at => { "$lt" => date }) }
  scope :between,       lambda { |start_date, end_date| where(:started_at => { "$gte" => start_date }, :ended_at => { "$lt" => end_date }) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :site_id,                    :presence => true
  validates :started_at,                 :presence => true
  validates :ended_at,                   :presence => true
  validates :loader_hits,                :presence => true
  validates :player_hits,                :presence => true
  validates :main_player_hits,           :presence => true
  validates :main_player_hits_cached,    :presence => true
  validates :dev_player_hits,            :presence => true
  validates :dev_player_hits_cached,     :presence => true
  validates :invalid_player_hits,        :presence => true
  validates :invalid_player_hits_cached, :presence => true
  validates :flash_hits,                 :presence => true
  validates :requests_s3,                :presence => true
  validates :traffic_s3,                 :presence => true
  validates :traffic_voxcast,            :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_dates_from_log, :on => :create
  after_save        :update_site_hits_cache
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_usages_from_trackers!(log, trackers)
    hbr    = hits_traffic_and_requests_from(trackers)
    tokens = tokens_from(hbr)
    while tokens.present?
      Site.where(:token => tokens.pop(100)).each do |site|
        create!(
          :log                        => log,
          :site                       => site,
          :loader_hits                => (hits = hbr[:loader_hits]) ? hits[site.token].to_i : 0,
          :player_hits                => (hits = hbr[:player_hits]) ? hits[site.token].to_i : 0,
          :main_player_hits           => (hits = hbr[:main_player_hits]) ? hits[site.token].to_i : 0,
          :main_player_hits_cached    => (hits = hbr[:main_player_hits_cached]) ? hits[site.token].to_i : 0,
          :dev_player_hits            => (hits = hbr[:dev_player_hits]) ? hits[site.token].to_i : 0,
          :dev_player_hits_cached     => (hits = hbr[:dev_player_hits_cached]) ? hits[site.token].to_i : 0,
          :invalid_player_hits        => (hits = hbr[:invalid_player_hits]) ? hits[site.token].to_i : 0,
          :invalid_player_hits_cached => (hits = hbr[:invalid_player_hits_cached]) ? hits[site.token].to_i : 0,
          :flash_hits                 => (hits = hbr[:flash_hits]) ? hits[site.token].to_i : 0,
          :requests_s3                => (requests = hbr[:requests_s3]) ? requests[site.token].to_i : 0,
          :traffic_s3                 => (bandwidth = hbr[:traffic_s3]) ? bandwidth[site.token].to_i : 0,
          :traffic_voxcast            => (bandwidth = hbr[:traffic_voxcast]) ? bandwidth[site.token].to_i : 0
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
      :loader_hits_cache     => loader_hits,
      :player_hits_cache     => player_hits,
      :flash_hits_cache      => flash_hits,
      :requests_s3_cache     => requests_s3,
      :traffic_s3_cache      => traffic_s3,
      :traffic_voxcast_cache => traffic_voxcast
    )
  end
  
  # Compact trackers from RequestLogAnalyzer
  def self.hits_traffic_and_requests_from(trackers)
    trackers.inject({}) do |trackers, tracker|
      case tracker.options[:title]
      when :loader_hits, :flash_hits, :requests_s3
        trackers[tracker.options[:title]] = tracker.categories
      when :player_hits
        tracker.categories.each do |array, hits|
          token, status, referrer = array[0], array[1], array[2]
          if site = Site.find_by_token(token)
            referrer_type = site.referrer_type(referrer)
            if status == 200
              player_hits_type = "#{referrer_type}_player_hits".to_sym
              trackers[player_hits_type] = player_hits_tracker(trackers, player_hits_type, token, hits)
            else # cached
              player_hits_type = "#{referrer_type}_player_hits_cached".to_sym
              trackers[player_hits_type] = player_hits_tracker(trackers, player_hits_type, token, hits)
            end
            trackers[:player_hits] = player_hits_tracker(trackers, :player_hits, token, hits)
          end
        end
      when :traffic_s3, :traffic_voxcast
        trackers[tracker.options[:title]] = tracker.categories.inject({}) do |tokens, (k,v)|
          tokens[k] = v[:sum]
          tokens
        end
      end
      trackers
    end
  end
  
  def self.player_hits_tracker(trackers, type, token, hits)
    trackers[type] ||= {}
    if trackers[type][token]
      trackers[type][token] += hits
    else
      trackers[type][token] = hits
    end
    trackers[type]
  end
  
  def self.tokens_from(hits_traffic_and_requests)
    hits_traffic_and_requests.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end
  
end