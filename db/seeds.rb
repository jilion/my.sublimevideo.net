Admin.create(email: "admin@sublimevideo.net", password: "123456", roles: ["god"])
puts "Admin admin@sublimevideo.net/123456 created!"

plans_attributes = [
  { name: "free",       cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
  { name: "sponsored",  cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 0 },
  { name: "trial",      cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 2 },
  { name: "plus",       cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
  { name: "premium",    cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
  { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
  { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
  { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
]
plans_attributes.each { |attributes| Plan.create!(attributes) }
puts "#{plans_attributes.size} plans created!"
