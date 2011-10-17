module SiteModules::Stats
  extend ActiveSupport::Concern

  module InstanceMethods

    def stats_retention_days
      if plan.stats_retention_days == 0 && stats_trial_started_at.to_i > BusinessModel.days_for_stats_trial.days.ago.to_i
        365 # Stats trial
      else
        plan.stats_retention_days
      end
    end

  end

end
