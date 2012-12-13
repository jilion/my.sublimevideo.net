if ENV['OPENREDIS_URL'].present?
  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 3) { Redis.new(url: ENV['OPENREDIS_URL']) }
else
  $redis = ConnectionPool::Wrapper.new(size: 1) { Redis.new }
end
