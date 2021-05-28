module Users::Import
  extend ActiveSupport::Concern

  module ClassMethods
    def import organization, username, password
      prefixes = get_prefixes_of_organizations
      prefix   = organization.prefix

      if prefixes.include? prefix
        import = import_from_file prefix
      else
        ldap_config = organization.ldap_config
        import      = ldap_config.import username, password
      end
    end

    def import_from_file prefix
      users   = {}
      options = { col_sep: ';' }
      rows    = []

      CSV.foreach(extra_users_info_attr(prefix, 'role_path'), options) do |row|
        key  = /\d+/.match(row[1])
        role = row[0].strip

        if role_allowed?(role) && key.present?
          if users.key? key[0]
            users[key[0]].push(role)
          else
            users[key[0]] = [role]
          end
        end
      end

      User.transaction do
        rows = import_extra_users_info_role(users, prefix)
      end

      rows
    end

    private

      def role_allowed? role
        excluded_roles.exclude?(role) && find_role(role).present?
      end

      def excluded_roles
        ['UserReplicLdap']
      end

      def import_extra_users_info_role entry, prefix
        fields        = [11, 30, 30, 6, 50, 30, 70, 1, 10, 8, 8]
        field_pattern = "A#{fields.join 'A'}"
        users         = []
        managers      = {}
        users_by_file = {}

        File.foreach(extra_users_info_file(prefix)) do |line|
          row     = line.unpack field_pattern
          manager = find_manager row[6]

          if (process_args = process_entry? entry, row)
            users << (result = process_entry entry, **process_args)
            user   = result[:user]

            if user.persisted?
              users_by_file[user.user] = user.user
              managers[user] = manager[0] if manager
            end
          end
        end

        assign_managers managers, users_by_file

        users
      end

      def process_entry? entry, row
        email = row[4]

        if email.present?
          people_user_id = row[0][0..4]

          if entry.key?(people_user_id)
            roles = find_role(entry[people_user_id])
            data  = trivial_data(row, people_user_id)
            user  = find_user data

            if user&.roles.blank? && roles.blank?
              false
            else
              { user: user, roles: roles, data: data }
            end
          end
        end
      end

      def process_entry entry, user:, roles:, data:
        state = if user
                  update_user user: user, data: data, roles: roles

                  if user.roles.any?
                    user.saved_changes? ? :updated : :unchanged
                  else
                    :deleted
                  end
                else
                  user = create_user(data, roles) if data.present?
                  :created
                end

        state = :errored if user.errors.any?

        { user: user, state: state }
      end

      def find_manager managers
        hierarchy  = managers.split(/\W/).reject &:blank?
         /\d+/.match(hierarchy.first) if hierarchy.present?
      end

      def find_user data
        User.group_list.by_email(data[:email])             ||
          User.without_organization.by_email(data[:email]) ||
          User.list.by_user(data[:user])
      end

      def update_user user: nil, data: nil, roles: nil
        new_roles = roles.map do |r|
          unless user.organization_roles.detect { |o_r| o_r.role_id == r.id }
            { organization_id: r.organization_id, role_id: r.id }
          end
        end

        removed_roles = user.organization_roles.map do |o_r|
          if roles.map(&:id).exclude? o_r.role_id
            { id: o_r.id, _destroy: '1' } if o_r.organization_id == Current.organization&.id
          end
        end

        data[:organization_roles_attributes] = new_roles.compact + removed_roles.compact

        user.update data
      end

      def create_user data, roles
        data[:organization_roles_attributes] = roles.map do |r|
          { organization_id: r.organization_id, role_id: r.id }
        end.compact

        User.create data
      end

      def find_role role
        Role.list_with_corporate.where(name: role)
      end

      def trivial_data row, user
        {
          name: row[2],
          last_name: row[1],
          user: user,
          email: row[4],
          hidden: false,
          enable: true
        }
      end

      def assign_managers managers, users_by_file
        managers.each do |user, manager|
          manager_id = if users_by_file[manager] == user.user
                         nil
                       else
                         User.find_by(user: manager)&.id
                       end

          user.reload.update manager_id: manager_id if manager_id
        end
      end

      def extra_users_info_file prefix
        path = extra_users_info_attr prefix, 'path'

        path if path && File.exist?(path)
      end

      def extra_users_info_format prefix
        extra_users_info_attr prefix, 'format'
      end

      def extra_users_info_attr(prefix, attr)
        if ENV['EXTRA_USERS_INFO'].present?
          file_info = JSON.parse ENV['EXTRA_USERS_INFO'] rescue {}

          file_info[prefix][attr]
        end
      end

      def get_prefixes_of_organizations
        prefixes = []

        if ENV['EXTRA_USERS_INFO'].present?
          prefixes = JSON.parse ENV['EXTRA_USERS_INFO'] rescue {}
          prefixes = prefixes.keys
        end
      end
    end
end
