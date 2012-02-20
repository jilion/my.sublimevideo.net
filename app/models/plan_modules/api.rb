module PlanModules::Api
  extend ActiveSupport::Concern

  included do
    acts_as_api

    api_accessible :v1_private_self do |template|
      template.add :name
      template.add :cycle
      template.add :video_views, :as => :video_views
    end
  end

end
