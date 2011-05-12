module SiteUsage::Api
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def to_api(usages)
      usages.each_with_object({}) do |usage, hash|
        hash[usage.day.strftime("%Y-%m-%d")] = usage.billable_player_hits
      end
    end
  end

  module InstanceMethods
  end
end
