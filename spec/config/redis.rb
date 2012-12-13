require 'redis'
require 'connection_pool'

RSpec.configure do |config|
  config.before :each, redis: true do
    $redis.flushall if defined?($redis)
  end
end
