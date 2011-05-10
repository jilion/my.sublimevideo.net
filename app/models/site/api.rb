module Site::Api
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
  end

  module InstanceMethods
    def to_api
      {
        token: token,
        main_domain: hostname,
        dev_domains: dev_hostnames.try(:split, ', '),
        extra_domains: extra_hostnames.try(:split, ', '),
        wildcard: wildcard?,
        path: path,
        plan: plan.to_api,
        next_plan: next_cycle_plan.try(:to_api) || {},
        started_at: plan_started_at.to_datetime,
        cycle_started_at: plan_cycle_started_at.to_datetime,
        cycle_ended_at: plan_cycle_ended_at.to_datetime,
        refundable: refundable?,
        peak_insurance_activated: plan_player_hits_reached_notification_sent_at?,
        upgrade_required: first_plan_upgrade_required_alert_sent_at?
      }
    end
  end
end