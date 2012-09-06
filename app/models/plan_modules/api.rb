module PlanModules::Api
  extend ActiveSupport::Concern

  included do
    acts_as_api

    api_accessible :v1_self_private do |template|
      template.add :name
      template.add :cycle
      template.add :video_views, as: :video_views
    end
  end

end
