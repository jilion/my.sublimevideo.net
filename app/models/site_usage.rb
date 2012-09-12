require_dependency 'notify'
require_dependency 'log_analyzer'

class SiteUsage
  include Mongoid::Document
  include SiteUsageModules::Api

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

  # ================
  # = Associations =
  # ================

  def site
    Site.find_by_id(site_id)
  end

  # =================
  # = Class Methods =
  # =================

  def self.create_usages_from_trackers!(log, trackers)
    hbrs   = hits_traffic_and_requests_from(log, trackers)
    tokens = tokens_from(hbrs)
    while tokens.present?
      Site.where(token: tokens.pop(100)).each do |site|
        begin
          hbr_token = hits_traffic_and_requests_for_token(hbrs, site.token)
          self.collection
            .find(site_id: site.id, day: log.day)
            .update({ :$inc => hbr_token }, upsert: true)
        rescue => ex
          Notify.send("Error on site_usage (#{site.id}, #{log.day}) update (from log #{log.hostname}, #{log.name}. Data: #{hbr_token}", exception: ex)
        end
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def billable_player_hits
    main_player_hits.to_i + main_player_hits_cached.to_i + extra_player_hits.to_i + extra_player_hits_cached.to_i
  end

private

  # Compact trackers from RequestLogAnalyzer
  def self.hits_traffic_and_requests_from(log, trackers)
    trackers.inject({}) do |trackers, tracker|
      case tracker.options[:title]
      when :flash_hits, :requests_s3
        trackers[tracker.options[:title]] = tracker.categories
      when :loader_hits
        tracker.categories.each do |array, hits|
          token, referrer = array
          if referrer =~ /^https.*/
            trackers[:ssl_loader_hits] = set_hits_tracker(trackers, :ssl_loader_hits, token, hits)
          end
          trackers[:loader_hits] = set_hits_tracker(trackers, :loader_hits, token, hits)
        end
      when :player_hits
        tracker.categories.each do |array, hits|
          token, status, referrer = array
          if site = Site.find_by_token(token)
            # Don't use log.started_at to prevent error with new site created during the log creation
            referrer_type = site.referrer_type(referrer, log.ended_at)
            if status == 200
              player_hits_type = "#{referrer_type}_player_hits".to_sym
              trackers[player_hits_type] = set_hits_tracker(trackers, player_hits_type, token, hits)
            else # cached
              player_hits_type = "#{referrer_type}_player_hits_cached".to_sym
              trackers[player_hits_type] = set_hits_tracker(trackers, player_hits_type, token, hits)
            end
            trackers[:player_hits] = set_hits_tracker(trackers, :player_hits, token, hits)
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

  def self.hits_traffic_and_requests_for_token(hbrs, token)
    hbr_attributes = [
     :loader_hits, :ssl_loader_hits, :player_hits,
     :main_player_hits, :main_player_hits_cached,
     :extra_player_hits, :extra_player_hits_cached,
     :dev_player_hits, :dev_player_hits_cached,
     :invalid_player_hits, :invalid_player_hits_cached,
     :flash_hits, :requests_s3, :traffic_s3, :traffic_voxcast
    ]
    hbr_attributes.inject({}) do |token_hbr, attribute|
     value = (hbr = hbrs[attribute]) ? hbr[token].to_i : 0
     token_hbr[attribute] = value
     token_hbr
    end
  end

  def self.set_hits_tracker(trackers, type, token, hits)
    trackers[type] ||= {}
    if trackers[type][token]
      trackers[type][token] += hits
    else
      trackers[type][token] = hits
    end
    trackers[type]
  end

  def self.tokens_from(hbrs)
    hbrs.inject([]) do |tokens, (k, v)|
      tokens += v.collect { |k, v| k }
    end.compact.uniq
  end

end
