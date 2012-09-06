module SiteModules::Api
  extend ActiveSupport::Concern

  included do

    acts_as_api

    api_accessible :v1_self_private do |template|
      template.add :token
      template.add :hostname, as: :main_domain
      template.add lambda { |site| site.dev_hostnames.try(:split, ', ') || [] }, as: :dev_domains
      template.add lambda { |site| site.extra_hostnames.try(:split, ', ') || [] }, as: :extra_domains
      template.add lambda { |site| site.wildcard? }, as: :wildcard
      template.add lambda { |site| site.path || '' }, as: :path
      template.add :plan
      template.add :next_cycle_plan
      template.add lambda { |site| site.plan_started_at.try(:to_datetime) }, as: :started_at
      template.add lambda { |site| site.plan_cycle_started_at.try(:to_datetime) }, as: :cycle_started_at
      template.add lambda { |site| site.plan_cycle_ended_at.try(:to_datetime) }, as: :cycle_ended_at
      template.add lambda { |site| site.overusage_notification_sent_at? }, as: :peak_insurance_activated
      template.add lambda { |site| site.first_plan_upgrade_required_alert_sent_at? }, as: :upgrade_required
    end

    api_accessible :v1_usage_private do |template|
      template.add :token
      template.add lambda { |site| site.usages.between(60.days.ago.midnight, Time.now.utc.end_of_day) }, as: :usage, template: :v1_self_private
    end

  end

end
