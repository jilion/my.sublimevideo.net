class Stat::Site
  include Mongoid::Document
  include Stat
  store_in :site_stats

  field :t,  :type => String # Site token

  field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

  index [[:t, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

  def site
    Site.find_by_token(t)
  end

  # ====================
  # = Instance Methods =
  # ====================

  def token
    read_attribute(:t)
  end

  # only main & extra hostname are counted in charts
  def billable_pv
    pv['m'].to_i + pv['e'].to_i
  end

  # only main & extra hostname are counted in charts
  def billable_vv
    vv['m'].to_i + vv['e'].to_i
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id'] = time
    json['pv'] = billable_pv if billable_pv > 0
    json['vv'] = billable_vv if billable_vv > 0
    json
  end


end
