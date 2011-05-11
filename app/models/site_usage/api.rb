module SiteUsage::Api
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def to_api(start_date=60.days.ago.midnight, end_date=Time.now.utc.end_of_day)
      between(start_date, end_date).each_with_object({}) do |usage, hash|
        hash[usage.day.strftime("%Y-%m-%d")] = usage.billable_player_hits
      end
    end
  end

  module InstanceMethods
  end
end
