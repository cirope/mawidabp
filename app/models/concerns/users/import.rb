module Users::Import
  extend ActiveSupport::Concern

  module ClassMethods
    def import organization, username = nil, password = nil
      prefixes = extra_users_info_prefixes
      prefix   = organization.prefix

      if prefixes.include? prefix
        import_from_file prefix
      else
        ldap_config = organization.ldap_config

        ldap_config.import username, password
      end
    end

    def import_from_file prefix
      if extra_users_info_format(prefix) == 'peoplesoft_txt'
        peoplesoft_file prefix
      elsif extra_users_info_format(prefix) == 'pat_txt'
        pat_file prefix
      else
        raise I18n.t 'errors.messages.unknown_format'
      end
    end

    def pat_file prefix
      options  = { col_sep: ';', headers: true }

      CSV.foreach(extra_users_info_attr(prefix, 'path'), **options) do |row|
        roles  = find_role I18n.t 'role.type_audited'
        header = extra_users_info_headers prefix
        data   = trivial_data_pat header, row
        user   = find_user data

        User.transaction do
          if roles.present?
            user_audited = user if user&.can_act_as_audited?
            process_args = { user: user_audited, roles: roles, data: data }

            process_entry user, **process_args
          end
        end
      end
    end

    def peoplesoft_file prefix
      users   = {}
      options = { col_sep: ';' }

      CSV.foreach(extra_users_info_attr(prefix, 'role_path'), **options) do |row|
        user_ldap = row[1]&.sub(/.*?uid=(.*?),.*/i, '\1')&.to_s
        username  = user_ldap[/\d+/]
        role      = row[0].strip
        ou        = row[1]&.gsub /\A(cn|uid)=[\w\s]+,/i, ''

        if role_allowed?(role) && username.present?
          users[username]        ||= {}
          users[username][:role] ||= []

          users[username][:role] << role

          users[username].merge!(user: user_ldap, ou: ou)
        end
      end

      User.transaction do
        import_extra_users_info_role users, prefix
      end
    end

    def log_error error
      Rails.logger.error error
    end

    def file_log_error error
      logger = Logger.new "log/import_#{Time.zone.today.to_s :db}.log"

      logger.error "Exception occurred import\n#{error}"
    end

    private

      def role_allowed? role
        find_role(role).present?
      end

      def import_extra_users_info_role entry, prefix
        fields        = [11, 30, 30, 6, 50, 30, 70, 1, 10, 8, 8]
        field_pattern = "A#{fields.join 'A'}"
        users         = []
        managers      = {}
        users_by_file = {}

        File.foreach(extra_users_info_file(prefix)) do |line|
          row = line.unpack field_pattern

          if (process_args = process_entry? entry, row)
            users << (result = process_entry entry, **process_args)
            user   = result[:user]

            if user.persisted?
              users_by_file[user.user] = user.user

              manager = find_manager row[6], user

              managers[user] = manager if manager
            end
          end
        end

        assign_managers managers, users_by_file

        users
      end

      def process_entry? entry, row
        email = row[4]

        if email.present?
          username = row[0][0..4]

          if entry.key?(username)
            roles = find_role(entry[username][:role])
            data  = trivial_data(row, entry[username])
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

        if user.errors.any?
          state = :errored
          error = [:errored, "user: #{user.user}", user.errors.messages].join ' - '

          log_error error
          file_log_error error
        end

        { user: user, state: state }
      end

      def find_manager managers, user
        hierarchy = managers.split(/\W/).reject &:blank?

        if hierarchy.present?
          if hierarchy.last == user.user
            hierarchy[-2]
          else
            hierarchy.last
          end
        end
      end

      def create_user data, roles
        data[:organization_roles_attributes] = roles.map do |r|
          { organization_id: r.organization_id, role_id: r.id }
        end.compact

        User.create data
      end

      def find_role role
        Role.list_with_corporate.where name: role
      end

      def trivial_data row, user
        {
          name: row[2],
          last_name: row[1],
          user: user[:user],
          email: row[4],
          hidden: false,
          enable: true,
          organizational_unit: user[:ou]
        }
      end

      def trivial_data_pat header, row
        {
          name: row[header['name']],
          last_name: row[header['lastname']],
          user: row[header['user']],
          email: row[header['email']],
          hidden: false,
          enable: true,
          organizational_unit: ''
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
        if EXTRA_USERS_INFO.has_key? prefix
          EXTRA_USERS_INFO[prefix][attr]
        end
      end

      def extra_users_info_prefixes
        EXTRA_USERS_INFO.keys
      end

      def extra_users_info_headers prefix
        extra_users_info_attr prefix, 'header'
      end
    end
end
