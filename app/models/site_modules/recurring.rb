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
        Site.in_trial.billable.where(first_paid_plan_started_at: nil).trial_expires_on(days_before_trial_end.days.from_now).find_each(batch_size: 100) do |site|
          My::BillingMailer.trial_will_end(site).deliver!
        end
      end
    end

  end

end
