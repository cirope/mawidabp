"#{Rails.root}/REVISION".tap do |version_file|
  APP_REVISION = File.exist?(version_file) ? File.read(version_file) : 'Dev'
end
