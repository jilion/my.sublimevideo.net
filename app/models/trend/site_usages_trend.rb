class SiteUsagesTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :lh, type: Hash,    default: {} # Loader hits: { ns (non-ssl) => 2, s (ssl) => 1 }
  field :ph, type: Hash,    default: {} # Player hits: { m (main non-cached) => 3, mc (main cached) => 1, e (extra non-cached) => 3, ec (extra cached) => 1, d (dev non-cached) => 3, dc (dev cached) => 1, i (invalid non-cached) => 3, ic (invalid cached) => 1 }
  field :fh, type: Integer, default: 0  # Flash hits
  field :sr, type: Integer, default: 0  # S3 Requests
  field :tr, type: Hash,    default: {} # Traffic (bytes): { s (s3) => 2123, v (voxcast) => 1231 }

  def self.json_fields
    [:lh, :ph, :fh, :sr, :tr]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      SiteUsage.order_by([:day, :asc]).first.day - 1.day
    end
  end

  def self.trend_hash(day)
    site_usages = SiteUsage.where(day: day.utc)

    {
      d:  day.utc,
      lh: loader_hits_hash(site_usages),
      ph: player_hits_hash(site_usages),
      fh: site_usages.sum(:flash_hits).to_i,
      sr: site_usages.sum(:requests_s3).to_i,
      tr: traffic_hash(site_usages)
    }
  end

  def self.loader_hits_hash(site_usages)
    all_loader_hits     = site_usages.sum(:loader_hits).to_i
    all_ssl_loader_hits = site_usages.sum(:ssl_loader_hits).to_i

    {
      ns: all_loader_hits - all_ssl_loader_hits,
      s: all_ssl_loader_hits
    }
  end

  def self.player_hits_hash(site_usages)
    {
      m: site_usages.sum(:main_player_hits).to_i,    mc: site_usages.sum(:main_player_hits_cached).to_i,
      e: site_usages.sum(:extra_player_hits).to_i,   ec: site_usages.sum(:extra_player_hits_cached).to_i,
      d: site_usages.sum(:dev_player_hits).to_i,     dc: site_usages.sum(:dev_player_hits_cached).to_i,
      i: site_usages.sum(:invalid_player_hits).to_i, ic: site_usages.sum(:invalid_player_hits_cached).to_i
    }
  end

  def self.traffic_hash(site_usages)
    {
      s: site_usages.sum(:traffic_s3).to_i,
      v: site_usages.sum(:traffic_voxcast).to_i
    }
  end

end
