namespace :epilady do
  desc 'Removes organizations with associated models'

  task pluck: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.lock_optimistically = false
    ActiveRecord::Base.logger = nil

    orgs_prefix = ['default', 'demo', 'frspv', 'jn', 'sil', 'qacrp', 'uai-inv', 'inv']

    Organization.where(prefix: orgs_prefix).each do |o|
      o.destroy
    end
  end
end
