if ENV['REDISTOGO_URL'].present?
  RedisConnection = Redis.new(url: ENV['REDISTOGO_URL'])
else
  RedisConnection = Redis.new
end
