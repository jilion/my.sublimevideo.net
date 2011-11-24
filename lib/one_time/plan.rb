module OneTime
  module Plan

    class << self

      def create_v2_plans
        [
          { name: "free",    cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
          { name: "plus",    cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
          { name: "premium", cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
          { name: "plus",    cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
          { name: "premium", cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 }
        ].each { |attributes| ::Plan.create!(attributes) }

        "New plans created!"
      end

    end

  end
end
