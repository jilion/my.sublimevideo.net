module Stats
  class SiteUsagesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :site_usages_stats

    field :d,  type: DateTime # Day
    field :lh, type: Hash,    default: {} # Loader hits: { ns (non-ssl) => 2, s (ssl) => 1 }
    field :ph, type: Hash,    default: {} # Player hits: { m (main non-cached) => 3, mc (main cached) => 1, e (extra non-cached) => 3, ec (extra cached) => 1, d (dev non-cached) => 3, dc (dev cached) => 1, i (invalid non-cached) => 3, ic (invalid cached) => 1 }
    field :fh, type: Integer, default: 0  # Flash hits
    field :sr, type: Integer, default: 0  # S3 Requests
    field :tr, type: Hash,    default: {} # Traffic (bytes): { s (s3) => 2123, v (voxcast) => 1231 }

    index :d

    # ==========
    # = Scopes =
    # ==========

    scope :between, lambda { |start_date, end_date| where(d: { "$gte" => start_date, "$lt" => end_date }) }

    # send time as id for backbonejs model
    def as_json(options = nil)
      json = super
      json['id'] = d.to_i
      json
    end

    # =================
    # = Class Methods =
    # =================

    class << self

      def json(from = nil, to = nil)
        json_stats = if from.present?
          between(from, to || Time.now.utc.midnight)
        else
          scoped
        end

        json_stats.order_by([:d, :asc]).to_json(only: [:lh, :ph, :fh, :sr, :tr])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_site_usages_stat(last_stat_day)
        end
      end

      def determine_last_stat_day
        if SiteUsagesStat.present?
          SiteUsagesStat.order_by([:d, :asc]).last.try(:d)
        else
          SiteUsage.order_by([:day, :asc]).first.day - 1.day
        end
      end

      def create_site_usages_stat(day)
        self.create(site_usages_hash(day))
      end

      def site_usages_hash(day)
        site_usages = SiteUsage.where(day: day.to_time)

        {
          d:  day.to_time,
          lh: loader_hits_hash(site_usages),
          ph: player_hits_hash(site_usages),
          fh: site_usages.sum(:flash_hits).to_i,
          sr: site_usages.sum(:requests_s3).to_i,
          tr: traffic_hash(site_usages)
        }
      end

      private

      def loader_hits_hash(site_usages)
        all_loader_hits     = site_usages.sum(:loader_hits).to_i
        all_ssl_loader_hits = site_usages.sum(:ssl_loader_hits).to_i

        {
          ns: all_loader_hits - all_ssl_loader_hits,
          s: all_ssl_loader_hits
        }
      end

      def player_hits_hash(site_usages)
        {
          m: site_usages.sum(:main_player_hits).to_i,    mc: site_usages.sum(:main_player_hits_cached).to_i,
          e: site_usages.sum(:extra_player_hits).to_i,   ec: site_usages.sum(:extra_player_hits_cached).to_i,
          d: site_usages.sum(:dev_player_hits).to_i,     dc: site_usages.sum(:dev_player_hits_cached).to_i,
          i: site_usages.sum(:invalid_player_hits).to_i, ic: site_usages.sum(:invalid_player_hits_cached).to_i
        }
      end

      def traffic_hash(site_usages)
        {
          s: site_usages.sum(:traffic_s3).to_i,
          v: site_usages.sum(:traffic_voxcast).to_i
        }
      end

    end

  end
end
