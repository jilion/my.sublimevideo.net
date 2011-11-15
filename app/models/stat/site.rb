class Stat::Site
  include Mongoid::Document
  include Stat
  store_in :site_stats

  field :t, type: String # Site token

  field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, type: Hash, default: {} # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, type: Hash, default: {} # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

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
# == Schema Information
#
# Table name: sites
#
#  id                                        :integer         not null, primary key
#  user_id                                   :integer
#  hostname                                  :string(255)
#  dev_hostnames                             :string(255)
#  token                                     :string(255)
#  license                                   :string(255)
#  loader                                    :string(255)
#  state                                     :string(255)
#  archived_at                               :datetime
#  created_at                                :datetime
#  updated_at                                :datetime
#  player_mode                               :string(255)     default("stable")
#  google_rank                               :integer
#  alexa_rank                                :integer
#  path                                      :string(255)
#  wildcard                                  :boolean
#  extra_hostnames                           :string(255)
#  plan_id                                   :integer
#  pending_plan_id                           :integer
#  next_cycle_plan_id                        :integer
#  cdn_up_to_date                            :boolean         default(FALSE)
#  first_paid_plan_started_at                :datetime
#  plan_started_at                           :datetime
#  plan_cycle_started_at                     :datetime
#  plan_cycle_ended_at                       :datetime
#  pending_plan_started_at                   :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_cycle_ended_at               :datetime
#  overusage_notification_sent_at            :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  refunded_at                               :datetime
#  last_30_days_main_video_views             :integer         default(0)
#  last_30_days_extra_video_views            :integer         default(0)
#  last_30_days_dev_video_views              :integer         default(0)
#  trial_started_at                          :datetime
#  badged                                    :boolean
#  last_30_days_invalid_video_views          :integer         default(0)
#  last_30_days_embed_video_views            :integer         default(0)
#  stats_trial_started_at                    :datetime
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_user_id                           (user_id)
#

