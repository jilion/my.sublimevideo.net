module Plan::Api
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
  end

  module InstanceMethods
    def to_api
      {
        name: name,
        cycle: cycle,
        video_pageviews: player_hits
      }
    end
  end
end