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
        dev_domains: dev_hostnames.try(:split, ', ') || [],
        extra_domains: extra_hostnames.try(:split, ', ') || [],
        wildcard: wildcard?,
        path: path || '',
        plan: plan.try(:to_api) || {},
        next_plan: next_cycle_plan.try(:to_api) || {},
        started_at: plan_started_at.try(:to_datetime),
        cycle_started_at: plan_cycle_started_at.try(:to_datetime),
        cycle_ended_at: plan_cycle_ended_at.try(:to_datetime),
        refundable: refundable?,
        peak_insurance_activated: plan_player_hits_reached_notification_sent_at?,
        upgrade_required: first_plan_upgrade_required_alert_sent_at?
      }
    end

    def usage_to_api(start_date=60.days.ago.midnight, end_date=Time.now.utc.end_of_day)
      {
        token: token,
        usage: SiteUsage.to_api(usages.between(start_date, end_date))
      }
    end

  end
end
