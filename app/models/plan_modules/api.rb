module PlanModules::Api
  extend ActiveSupport::Concern

  included do
    acts_as_api

    api_accessible :v1_private_self do |template|
      template.add :name
      template.add :cycle
      template.add :player_hits, :as => :video_pageviews
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end
