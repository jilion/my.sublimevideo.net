module SiteModules::Api
  extend ActiveSupport::Concern

  included do

    acts_as_api

    api_accessible :v1_self_private do |template|
      template.add :token
      template.add :hostname, as: :main_domain
      template.add lambda { |site| site.extra_hostnames.try(:split, ', ') || [] }, as: :extra_domains
      template.add lambda { |site| site.dev_hostnames.try(:split, ', ') || [] }, as: :dev_domains
      template.add lambda { |site| site.staging_hostnames.try(:split, ', ') || [] }, as: :staging_domains
      template.add lambda { |site| site.wildcard? }, as: :wildcard
      template.add lambda { |site| site.path || '' }, as: :path
      template.add :accessible_stage
    end

    api_accessible :v1_usage_private do |template|
      template.add :token
      template.add lambda { |site| site.usages.between(day: 60.days.ago.midnight..Time.now.utc.end_of_day) }, as: :usage, template: :v1_self_private
    end

  end

end
