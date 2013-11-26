namespace :epilady do
  desc 'Removes organizations with associated models'

  task start: :environment do
    orgs_prefix = ['jn']

    organizations = Organization.where(prefix: orgs_prefix)

    if organizations.present?
      organizations.each do |o|

        PaperTrail::Version.where(organization_id: o.id).find_each do |version|
          version.destroy
        end

        o.without_versioning { o.destroy }
      end
    else
      raise 'No organizations prefix loaded.'
    end
  end
end
