RedisConnection = Redis.connect(url: ENV['REDISTOGO_URL'] || 'http://127.0.0.1:6379')
