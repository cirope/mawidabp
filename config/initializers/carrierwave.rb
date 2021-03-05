CarrierWave.configure do |config|
  config.root = Rails.root
  config.enable_processing = !Rails.env.test?
  config.cache_dir = 'uploads/tmp'
end
