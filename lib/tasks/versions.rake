namespace :versions do
  desc 'Migrate old object YAML column to JSON'
  task migrate: :environment do
    PaperTrail::Version.where.not(old_object: nil, object: nil).find_each do |version|
      version.update! object: ActiveSupport::JSON.encode(YAML.load(version.old_object))
    end
  end
end
