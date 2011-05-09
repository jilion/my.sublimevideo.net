module Site::Api
  extend ActiveSupport::Concern
  
  included do
  end

  module ClassMethods
    def self.fields_for_api
      [:token, :hostname, :dev_hostnames, :extra_hostnames]
    end
  end

  module InstanceMethods
    def to_api(options={})
      {
        token: token,
        main_domain: hostname,
        dev_domains: dev_hostnames,
        extra_domains: extra_hostnames,
        wildcard: wildcard,
        path: path,
        plan: plan.to_api,
        next_plan: next_cycle_plan.try(:to_api) || {},
        started_at: plan_started_at,
        cycle_started_at: plan_cycle_started_at,
        cycle_ended_at: plan_cycle_ended_at,
        refundable: refundable?,
        peak_insurance_activated: plan_player_hits_reached_notification_sent_at?,
        upgrade_required: first_plan_upgrade_required_alert_sent_at?,
        last_30_days_video_pageviews: last_30_days_main_player_hits_total_count + last_30_days_extra_player_hits_total_count
      }
    end
  end
end