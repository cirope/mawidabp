"#{Rails.root}/REVISION".tap do |version_file|
  MW_VERSION = File.exists?(version_file) ? File.read(version_file) : 'Dev'
end
