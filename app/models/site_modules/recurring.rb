module SiteModules::Recurring
  extend ActiveSupport::Concern

  module ClassMethods

    def delay_update_last_30_days_counters_for_not_archived_sites
      unless Delayed::Job.already_delayed?('%Site%update_last_30_days_counters_for_not_archived_sites%')
        delay(run_at: Time.now.utc.tomorrow.midnight + 5.minutes).update_last_30_days_counters_for_not_archived_sites
      end
    end

    def update_last_30_days_counters_for_not_archived_sites
      delay_update_last_30_days_counters_for_not_archived_sites

      not_archived.find_each(batch_size: 100) do |site|
        site.update_last_30_days_counters
      end
    end

    def delay_send_trial_will_end
      unless Delayed::Job.already_delayed?('%Site%send_trial_will_end%')
        delay(run_at: Time.now.utc.tomorrow.midnight).send_trial_will_end
      end
    end

    def send_trial_will_end
      delay_send_trial_will_end

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        in_trial.trial_expires_on(days_before_trial_end.days.from_now).find_each(batch_size: 100) do |site|
          BillingMailer.trial_will_end(site).deliver!
        end
      end
    end

    def delay_stop_stats_trial
      unless Delayed::Job.already_delayed?('%Site%stop_stats_trial%')
        delay(run_at: Time.now.utc.tomorrow.midnight).stop_stats_trial
      end
    end

    def stop_stats_trial
      delay_stop_stats_trial

      not_archived.where(stats_trial_started_at: BusinessModel.days_for_stats_trial.days.ago.midnight).find_each(batch_size: 100) do |site|
        Site.delay.update_loader_and_license(site.id, license: true)
      end
    end

    def delay_send_stats_trial_will_end
      unless Delayed::Job.already_delayed?('%Site%send_stats_trial_will_end%')
        delay(run_at: Time.now.utc.tomorrow.midnight).send_stats_trial_will_end
      end
    end

    def send_stats_trial_will_end
      delay_send_stats_trial_will_end

      not_archived.where(stats_trial_started_at: BusinessModel.days_before_stats_trial_end.days.ago.midnight).find_each(batch_size: 100) do |site|
        StatMailer.stats_trial_will_end(site).deliver!
      end
    end

  end

end
