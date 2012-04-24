RSpec.configure do |config|

  config.before(:each) do
    if defined?(RedisConnection)
      RedisConnection.flushall
    end
  end

end