require_relative '../epilady/logger'

namespace :epilady do
  desc 'Removes organizations with associated models'

  task pluck: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.lock_optimistically = false
    ActiveRecord::Base.logger = nil

    identifications = ['default', 'demo', 'frspv', 'jn', 'sil', 'qacrp', 'uai-inv', 'inv']
    organizations = Organization.where(prefix: identifications)
    organizations_ids = organizations.map(&:id)

    organizations.map(&:destroy)

    PaperTrail::Version.find_each do |version|
      begin
        model = version.reify

        if model.respond_to?(:organization_id) &&
          organizations_ids.include?(model.organization_id)

          version.destroy
        end
      rescue Exception => e
        Epilady::Logger.log e.message

        version.destroy
      end
    end
  end
end
