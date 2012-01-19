module Stats
  class SitesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :sites_stats

    # Legacy
    field :states_count, type: Hash
    field :plans_count,  type: Hash

    field :d,  type: DateTime # Day
    field :fr, type: Hash     # free { "beta" => 2, "dev" => 3, "free" => 4 }
    field :sp, type: Integer  # sponsored
    field :tr, type: Hash     # trial: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :pa, type: Hash     # paying: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :su, type: Integer  # suspended
    field :ar, type: Integer  # archived

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

    # def active
    #   fr.to_i + sp.to_i + tr.inject(0) { |sum, s| sum + s.value.inject(0) { |sum2, s2| sum2 += s2.value } }
    # end

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
          delay(:run_at => Time.now.utc.tomorrow.midnight).create_sites_stats # every day
        end
      end

      def create_sites_stats
        delay_create_sites_stats

        self.create(hash_for_sites)
      end

      def hash_for_sites
        hash = {
          d: Time.now.utc.midnight,
          fr: { free: Site.active.in_plan('free').count },
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

    end

  end
end
