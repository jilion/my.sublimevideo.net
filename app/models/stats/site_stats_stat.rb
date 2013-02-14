module Stats
  class SiteStatsStat < Base
    store_in collection: 'site_stats_stats'

    field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

    index d: 1

    def self.json_fields
      [:pv, :vv, :md, :pb]
    end

    def self.determine_last_stat_day
      if SiteStatsStat.present?
        SiteStatsStat.order_by(d: 1).last.try(:d)
      else
        Stat::Site::Day.order_by(d: 1).first.d - 1.day
      end
    end

    def self.stat_hash(day)
      site_stats = Stat::Site::Day.where(d: day.to_time).all

      {
        d:  day.to_time,
        pv: hashes_values_sum(site_stats, :pv),
        vv: hashes_values_sum(site_stats, :vv),
        bp: hashes_values_sum(site_stats, :bp),
        md: player_mode_hashes_values_sum(site_stats)
      }
    end

    def self.hashes_values_sum(site_stats, attribute)
      site_stats.only(attribute).map(&attribute).inject({}) do |memo, el|
        memo.merge(el) { |k, old_v, new_v| old_v + new_v }
      end
    end

    def self.player_mode_hashes_values_sum(site_stats)
      modes_and_devices = site_stats.map(&:md) # { Player Mode => { Device => N } }

      [:h, :f].inject({}) do |hash, key|
        mapped_mode_and_devices = modes_and_devices.map { |mode_and_devices| mode_and_devices[key.to_s] || {} }
        hash[key] = player_mode_hash_values_sum(mapped_mode_and_devices)
        hash
      end
    end

    def self.player_mode_hash_values_sum(modes_and_devices)
      modes_and_devices.inject do |hash, mode_and_devices|
        hash.merge(mode_and_devices) { |k, old_v, new_v| old_v + new_v }
      end
    end

  end
end
