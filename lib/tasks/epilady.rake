namespace :epilady do
  desc 'Removes organizations with associated models'

  task pluck: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.lock_optimistically = false

    orgs_prefix = ['inv']

    Organization.where(prefix: orgs_prefix).each do |o|

      users_ids = OrganizationRole.where(
        organization_id: o.id
      ).map(&:user).map(&:id).uniq

      o.destroy
    end
=begin
      current_users_ids = OrganizationRole.where(
        'user_id IN (?)', users_ids
      ).map(&:user).map(&:id).uniq

      users = User.find(users_ids - current_users_ids)

      users.each { |u| u.destroy }
    end
=end
  end
end
