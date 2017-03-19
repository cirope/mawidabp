"#{Rails.root}/REVISION".tap do |version_file|
  APP_REVISION = File.exists?(version_file) ? File.read(version_file) : 'Dev'
end
