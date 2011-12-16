module Stats
  class SitesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :sites_stats

    # Legacy
    field :states_count, type: Hash
    field :plans_count,  type: Hash

    # New
    field :d,  type: DateTime  # Day
    field :fr, type: Integer # free
    field :sp, type: Integer # sponsored
    field :tr, type: Hash # trial
    field :pa, type: Hash # paying
    field :su, type: Integer # suspended
    field :ar, type: Integer # archived

    index :d
    index :created_at

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

    def active
      fr.to_i + sp.to_i + tr.inject(0) { |sum, s| sum + s.value.inject(0) { |sum2, s2| sum2 += s2.value } }
    end

    # =================
    # = Class Methods =
    # =================

    class << self

      def json(from = nil, to = nil)
        json_stats = if from.present?
          between(from: from, to: to || Time.now.utc.midnight)
        else
          scoped
        end

        json_stats.order_by([:d, :asc]).to_json(only: [:fr, :sp, :tr, :pa, :tr_details, :pa_details, :su, :ar])
      end

      def delay_create_sites_stats
        unless Delayed::Job.already_delayed?('%Stats::SitesStat%create_sites_stats%')
          delay(:run_at => Time.now.utc.tomorrow.midnight).create_sites_stats # every hour
        end
      end

      def create_sites_stats
        delay_create_sites_stats

        self.create(hash_for_sites.merge({
          d: Time.now.utc.midnight,
          # Legacy counters
          states_count: states_count,
          plans_count: plans_count
        }))
      end

      def hash_for_sites
        hash = {
          fr: Site.active.in_plan('free').count,
          sp: Site.active.in_plan('sponsored').count,
          tr: {},
          pa: {},
          su: Site.suspended.count,
          ar: Site.archived.count
        }

        Plan.paid_plans.each do |plan|
          scope = Site.active.in_plan_id(plan.id)
          sites_in_trial_count = scope.in_trial.count
          (hash[:tr][plan.name] ||= {})[plan.cycle[0]] = scope.in_trial.count

          sites_paying_count = scope.not_in_trial.count
          (hash[:pa][plan.name] ||= {})[plan.cycle[0]] = scope.not_in_trial.count
        end

        hash
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
end
