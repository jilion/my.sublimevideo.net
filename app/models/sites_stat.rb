class SitesStat
  include Mongoid::Document
  include Mongoid::Timestamps

  # Legacy
  field :states_count, :type => Hash
  field :plans_count,  :type => Hash

  # New
  field :d,      type: DateTime  # Day
  field :active, type: Hash # { fr (free) => 2, sp (sponsored) => 10, tr (trial) => { 8 => { m => 23, y => 20 }, 9 => { m => 13, y => 10 } }, pa (paying) => { 8 => { m => 23, y => 20 }, 9 => { m => 13, y => 10 } } }
  field :passive, type: Hash # { su (suspended) => suspended, ar (archived) => 2 }

  index :d
  index :created_at
  index [[:d, Mongo::ASCENDING], [:active, Mongo::ASCENDING]]
  index [[:d, Mongo::ASCENDING], [:passive, Mongo::ASCENDING]]

  # =================
  # = Class Methods =
  # =================

  class << self

    def delay_create_sites_stats
      unless Delayed::Job.already_delayed?('%SitesStat%create_sites_stats%')
        delay(:run_at => Time.now.utc.tomorrow.midnight).create_sites_stats # every hour
      end
    end

    def create_sites_stats
      delay_create_sites_stats

      self.create(
        d: Time.now.utc.midnight,
        # Legacy counters
        states_count: states_count,
        plans_count: plans_count,
        # New counters
        active: hash_for_active_sites,
        passive: hash_for_passive_sites
      )
    end

    def hash_for_active_sites
      hash = { tr: {}, pa: {} }
      hash[:fr] = Site.active.in_plan('free').count
      hash[:sp] = Site.active.in_plan('sponsored').count

      Plan.select("DISTINCT(name)").paid_plans.map(&:name).each do |plan_name|
        scope = Site.active.in_plan_id(Plan.where { name == plan_name }.map(&:id))
        sites_in_trial_count = scope.in_trial.count
        hash[:tr][plan_name] = sites_in_trial_count

        sites_paying_count = scope.not_in_trial.count
        hash[:pa][plan_name] = sites_paying_count
      end

      hash
    end

    def hash_for_passive_sites
      { su: Site.suspended.count, ar: Site.archived.count}
    end

    # Legacy counters
    def states_count
      states = Site.select("DISTINCT(state), id").order(:id).map(&:state)
      states.inject({}) do |states_count, state|
        states_count[state] = Site.with_state(state.to_sym).count
        states_count
      end
    end

    def plans_count
      plan_ids = Site.select("DISTINCT(plan_id)").order(:plan_id).map(&:plan_id)
      plan_ids.inject({}) do |plans_count, plan_id|
        plans_count[plan_id.to_s] = Site.in_plan_id(plan_id).count
        plans_count
      end
    end
    
  end
  
end
