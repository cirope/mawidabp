module Organizations::Roles
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_roles

    has_many :roles, dependent: :destroy
    has_many :organization_roles, dependent: :destroy
  end

  def users_with_roles(*roles)
    role_types = roles.map { |role| ::Role::TYPES[role.to_sym] }

    users.includes(
      organization_roles: :role
    ).where(
      roles: {
        role_type: role_types
      }
    ).uniq
  end

  private

    def create_initial_roles
      Role::TYPES.each do |type, value|
        role = roles.build name: I18n.t("role.type_#{type}"), role_type: value

        role.inject_auth_privileges Hash.new(Hash.new(true))

        ALLOWED_MODULES_BY_TYPE[type].each do |mod|
          role.privileges.build(
            module: mod.to_s,
            read: true,
            modify: true,
            erase: true,
            approval: true
          )
        end
      end
    end
end
