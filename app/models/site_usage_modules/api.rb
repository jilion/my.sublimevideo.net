module SiteUsageModules::Api
  extend ActiveSupport::Concern

  included do
    acts_as_api

    api_accessible :v1_self_private do |template|
      template.add lambda { |usage| usage.day.strftime("%Y-%m-%d") }, as: :day
      template.add lambda { |usage| usage.billable_player_hits }, as: :video_views
    end
  end

end
