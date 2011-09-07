module Site::Recurring
  extend ActiveSupport::Concern

  module ClassMethods

    def delay_update_last_30_days_counters_for_not_archived_sites
      unless Delayed::Job.already_delayed?('%Site%update_last_30_days_counters_for_not_archived_sites%')
        delay(run_at: Time.now.utc.tomorrow.midnight + 1.hour).update_last_30_days_counters_for_not_archived_sites
      end
    end

    def delay_send_trial_will_end
      unless Delayed::Job.already_delayed?('%Site%delay_send_trial_will_end%')
        delay(run_at: Time.now.utc.tomorrow.midnight).send_trial_will_end
      end
    end

    def update_last_30_days_counters_for_not_archived_sites
      delay_update_last_30_days_counters_for_not_archived_sites
      not_archived.find_each(:batch_size => 100) do |site|
        site.update_last_30_days_counters
      end
    end

    def send_trial_will_end
      delay_send_trial_will_end
      # in_trial.trial_ended_in()
    end

  end

end
