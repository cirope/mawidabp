module LdapConfigs::ExtraUsersInfo
  extend ActiveSupport::Concern

  private

    def import_extra_users_info
      return unless import_extra_users_info?

      fields        = [11, 30, 30, 6, 50, 30, 70, 1, 10, 8, 8]
      field_pattern = "A#{fields.join 'A'}"

      File.foreach(extra_users_info_file) do |line|
        row        = line.unpack field_pattern
        hierarchy  = row[6].split(/\W/).reject &:blank?
        manager    = User.list.by_user hierarchy.first
        conditions = [
          "LOWER(#{User.quoted_table_name}.#{User.qcn 'name'}) = ?",
          "LOWER(#{User.quoted_table_name}.#{User.qcn 'last_name'}) = ?"
        ].join ' AND '

        user = manager &&
                 User.list.where(conditions, row[2].downcase, row[1].downcase).take

        user.update(
          {
            manager_id: manager.id,
            email: row[4].downcase
          }
        ) if user
      end
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
