class Stat::Site
  include Mongoid::Document
  include Stat
  store_in :site_stats

  field :t, type: String # Site token

  field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }

  index :d # for Stats::SiteStatsStat#create_site_stats_stat
  index :h
  index :m
  index :s
  index [[:t, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

  # ====================
  # = Instance Methods =
  # ====================

  def site
    Site.find_by_token(t)
  end

  def token
    read_attribute(:t)
  end

  # only main & extra hostname are counted in charts
  def chart_pv
    pv['m'].to_i + pv['e'].to_i
  end

  # only main & extra hostname are counted in charts
  def chart_vv
    vv['m'].to_i + vv['e'].to_i
  end

  # main & extra hostname, with main & extra embed
  def billable_vv
    chart_vv + vv['em'].to_i
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id']  = time
    json['pv']  = chart_pv unless chart_pv.zero?
    json['vv']  = chart_vv unless chart_vv.zero?
    json['bvv'] = billable_vv if d? && !billable_vv.zero?
    json
  end

end
