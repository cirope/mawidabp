namespace :epilady do
  desc 'Removes organizations with associated models'

  task pluck: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.lock_optimistically = false
    ActiveRecord::Base.logger = nil

    orgs_prefix = ['spv']

    Organization.where(prefix: orgs_prefix).each do |o|
      o.destroy
    end
  end
end
