require 'redis'

RSpec.configure do |config|
  config.before do
    RedisConnection.flushall if defined?(RedisConnection)
  end
end
