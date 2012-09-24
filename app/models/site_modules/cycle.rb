require_dependency 'business_model'

module SiteModules::Cycle
  extend ActiveSupport::Concern

  module ClassMethods

    # def send_trial_will_expire_email
    #   BusinessModel.days_before_trial_end.each do |days_before_trial_end|
    #     Site.trial_expires_on(days_before_trial_end.days.from_now).
    #     find_each(batch_size: 100) do |site|
    #       BillingMailer.delay.trial_will_expire(site.id)
    #     end
    #   end
    # end

    # def downgrade_sites_leaving_trial
    #   Site.trial_ended.find_each(batch_size: 100) do |site|
    #     site.plan_id = Plan.free_plan.id
    #     site.skip_password(:save!)
    #     BillingMailer.delay.trial_has_expired(site.id)
    #   end
    # end

    # def renew_active_sites
    #   Site.renewable.each do |site|
    #     site.prepare_pending_attributes(false)
    #     site.skip_password(:save!)
    #   end
    # end

  end

  # def trial_expires_on(timestamp)
  #   in_trial_plan? && plan_started_at == (timestamp - BusinessModel.days_for_trial.days).midnight
  # end

  # def trial_expires_in_less_than_or_equal_to(timestamp)
  #   in_trial_plan? && plan_started_at <= (timestamp - BusinessModel.days_for_trial.days).midnight
  # end

  # def trial_end
  #   in_trial_plan? ? (plan_started_at + BusinessModel.days_for_trial.days).yesterday.end_of_day : nil
  # end

end
