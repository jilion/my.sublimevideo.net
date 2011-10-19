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

    def stats_trial_start_time
      stats_trial_started_at.to_i
    end

    def stats_trial_ended_at
      stats_trial_started_at && stats_trial_started_at + BusinessModel.days_for_stats_trial.days
    end

  end

end
