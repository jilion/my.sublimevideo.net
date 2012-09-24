if ENV['REDISTOGO_URL'].present?
  $redis = Redis.new(url: ENV['REDISTOGO_URL'])
else
  $redis = Redis.new
end
