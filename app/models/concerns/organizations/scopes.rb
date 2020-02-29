module Organizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered,   -> { order name: :asc }
    scope :corporate, -> { where corporate: true }
  end

  def users_with_roles(*roles)
    role_types = roles.map { |role| ::Role::TYPES[role.to_sym] }

    users = self.users.includes(
      organization_roles: :role
    ).where(
      roles: {
        role_type:       role_types,
        organization_id: id
      }
    )

    if POSTGRESQL_ADAPTER
      users.distinct
    else
      User.where id: users.pluck(:id).uniq
    end
  end

  module ClassMethods
    def with_group group
      where group_id: group.id
    end

    def with_ldap_config
      includes(:ldap_config).where.not ldap_configs: { organization_id: nil }
    end

    def without_ldap_config
      includes(:ldap_config).where ldap_configs: { organization_id: nil }
    end

    def list_with_selected group, selected_organization
      organizations = if Current.organization&.ldap_config&.present?
                        with_group(group).includes :ldap_config
                      else
                        with_group(group).without_ldap_config
                      end

      if selected_organization
        organizations.or with_group(group).
          includes(:ldap_config).
          where id: [selected_organization.id, Current.organization&.id].compact
      else
        organizations
      end
    end

    def by_subdomain subdomain
      where("LOWER(#{qcn('prefix')}) = ?", subdomain.to_s.downcase).take
    end
  end
end
