module Users::Import
  extend ActiveSupport::Concern

  module ClassMethods
    def import_from_file
      users = {}
      roles = []

      File.foreach(extra_users_info_file_role) do |line|
        row  = line.split(';')
        key  = /\d+/.match(row[1])
        role = row[0].strip

        if role != 'UserReplicLdap' && key.present?
          users[key[0]] = {
            id: row[1].strip,
            role: role
          }

          roles.push(role).uniq
        end
      end

        import_extra_users_info_role users, roles
    end

    private

    def import_extra_users_info_role users, roles
      fields        = [11, 30, 30, 6, 50, 30, 70, 1, 10, 8, 8]
      field_pattern = "A#{fields.join 'A'}"
      data          = []

      roles = get_roles roles

      File.foreach(extra_users_info_file) do |line|
        row = line.unpack field_pattern

        if row[4].present?
          user_people = row[0][0..4]

          if users.key?(user_people) && roles.include?(users[user_people][:role])
            user = users[user_people]

            data.push(trivial_data(row, user))
          end
        end
      end

      create_user data if data.present?
    end


    def create_user data
      User.transaction do
        u = User.first_or_create!(data)
      end
    end

    def get_roles roles
      Role.list.where(name: roles).pluck(:name)
    end

    def trivial_data row, user
      {
        name: row[2],
        last_name: row[1],
        user: user[:id],
        email: row[4],
        hidden:              false,
        enable:              true,
        organization_roles_attributes: [
          {
            organization_id: Current.organization.id,
            role_id: Role.find_by(name: user[:role]).id
          }
        ]
      }
    end

    def import_extra_users_info?
      extra_users_info_file && extra_users_info_format == 'peoplesoft_txt'
    end

    def extra_users_info_file
      #path = extra_users_info_attr 'path'
      path = 'scripts/MW-PERSONAL_test.TXT'

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

    def extra_users_info_file_role
      path = 'scripts/mw_l_.csv'

      path if path && File.exist?(path)
    end
  end
end
