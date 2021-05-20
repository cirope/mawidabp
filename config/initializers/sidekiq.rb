redis_server = ENV['REDIS_HOST'] || 'localhost'
redis_port   = ENV['REDIS_PORT'] || 6379
redis_url    = "redis://#{redis_server}:#{redis_port}/1"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
