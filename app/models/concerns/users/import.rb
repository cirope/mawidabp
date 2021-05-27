module Users::Import
  extend ActiveSupport::Concern

  module ClassMethods
    def import_from_file
      users   = {}
      options = {'col_sep': ';'}
      rows    = []

      CSV.foreach(extra_users_info_attr('role_path'), options) do |row|
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
        rows = import_extra_users_info_role(users)
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

      def import_extra_users_info_role users
        fields         = [11, 30, 30, 6, 50, 30, 70, 1, 10, 8, 8]
        field_pattern  = "A#{fields.join 'A'}"
        users_imported = []

        File.foreach(extra_users_info_file) do |line|
          row   = line.unpack field_pattern
          email = row[4]

          if email.present?
            people_user_id = row[0][0..4]

            if users.key?(people_user_id)
              roles = users[people_user_id]
              data  = trivial_data(row, people_user_id)
              user  = find_user data

              if user.nil?
                users_imported  << create_user(data, roles) if data.present?
              else
                users_imported << user
              end
            end
          end
        end

        users_imported
      end


      def find_user data
        User.group_list.by_email(data[:email])             ||
          User.without_organization.by_email(data[:email]) ||
          User.list.by_user(data[:user])
      end

      def create_user data, roles
        data[:organization_roles_attributes] = roles.map do |r|
          { organization_id: r.organization_id, role_id: r.id }
        end.compact

        User.first_create(data)
      end

      def find_role role
        Role.list.find_by(name: role)
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

      def import_extra_users_info?
        extra_users_info_file && extra_users_info_format == 'peoplesoft_txt'
      end

      def extra_users_info_file
        path = extra_users_info_attr 'path'

        path if path && File.exist?(path)
      end

      def extra_users_info_format
        extra_users_info_attr 'format'
      end

      def extra_users_info_attr(attr)
        if ENV['EXTRA_USERS_INFO'].present?
          file_info = JSON.parse ENV['EXTRA_USERS_INFO'] rescue {}

          file_info[attr]
        end
      end
    end
end
