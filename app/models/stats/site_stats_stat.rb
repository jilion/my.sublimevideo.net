module Stats
  class SiteStatsStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :site_stats_stats

    field :d,  type: DateTime # Day
    field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

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

        json_stats.order_by([:d, :asc]).to_json(only: [:pv, :vv, :md, :pb])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_site_stats_stat(last_stat_day)
        end
      end

      def determine_last_stat_day
        if SiteStatsStat.present?
          SiteStatsStat.order_by([:d, :asc]).last.try(:d)
        else
          Stat::Site.where(d: { "$ne" => nil }).order_by([:d, :asc]).first.d - 1.day
        end
      end

      def create_site_stats_stat(day)
        site_stats = Stat::Site.where(d: day.to_time).all

        self.create(site_stats_hash(day, site_stats))
      end

      def site_stats_hash(day, site_stats)
        {
          d:  day.to_time,
          pv: hashes_values_sum(site_stats, :pv),
          vv: hashes_values_sum(site_stats, :vv),
          bp: hashes_values_sum(site_stats, :bp),
          md: player_mode_hashes_values_sum(site_stats)
        }
      end

      def hashes_values_sum(site_stats, attribute)
        site_stats.only(attribute).map(&attribute).inject({}) do |memo, el|
          memo.merge(el) { |k, old_v, new_v| old_v + new_v }
        end
      end

      def player_mode_hashes_values_sum(site_stats)
        md = site_stats.map(&:md)

        {
          h: md.map { |h| h["h"] || {} }.inject { |memo, el| memo.merge(el) { |k, old_v, new_v| old_v + new_v } },
          f: md.map { |h| h["f"] || {} }.inject { |memo, el| memo.merge(el) { |k, old_v, new_v| old_v + new_v } }
        }
      end

    end

  end
end
