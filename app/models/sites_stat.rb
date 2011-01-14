class SitesStat
  include Mongoid::Document
  include Mongoid::Timestamps

  field :states_count, :type => Hash
  field :plans_count, :type => Hash
  field :addons_count, :type => Hash

  index :created_at

  # =================
  # = Class Methods =
  # =================

  def self.delay_create_sites_stats
    unless Delayed::Job.already_delayed?('%SitesStat%create_sites_stats%')
      delay(:run_at => Time.new.utc.tomorrow.midnight).create_sites_stats # every hour
    end
  end

  def self.create_sites_stats
    delay_create_sites_stats
    self.create(
      :states_count => states_count,
      :plans_count  => plans_count,
      :addons_count => addons_count
    )
  end

  def self.states_count
    states = Site.select("DISTINCT(state)").map(&:state)
    states.inject({}) do |states_count, state|
      states_count[state] = Site.with_state(state.to_sym).count
      states_count
    end
  end

  def self.plans_count
    plan_ids = Site.select("DISTINCT(plan_id)").map(&:plan_id)
    plan_ids.inject({}) do |plans_count, plan_id|
      plans_count[plan_id.to_s] = Site.where(:plan_id => plan_id).count
      plans_count
    end
  end

  def self.addons_count
    addon_ids = AddonsSite.select("DISTINCT(addon_id)").map(&:addon_id)
    addon_ids.inject({}) do |addons_count, addon_id|
      addons_count[addon_id.to_s] = Site.joins(:addons).where(:addons_sites => { :addon_id => addon_id }).count
      addons_count
    end
  end

end