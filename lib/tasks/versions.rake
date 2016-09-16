namespace :versions do
  desc 'Migrate old object YAML column to JSON'
  task migrate: :environment do
    PaperTrail::Version.where.not(old_object: nil).find_each do |version|
      version.update_columns old_object: nil, object: YAML.load(version.old_object)
    end
  end
end
