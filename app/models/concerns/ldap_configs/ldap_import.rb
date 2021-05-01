module LdapConfigs::LdapImport
  extend ActiveSupport::Concern

  def import username, password
    connection ||= ldap username, password
    ldap_filter  = Net::LDAP::Filter.construct filter
    users_by_dn  = {}
    managers     = {}
    users        = []
    start_date   = 5.seconds.ago

    User.transaction do
      connection.search(base: basedn, filter: ldap_filter) do |entry|
        if (process_args = process_entry? entry)
          users << (result = process_entry entry, **process_args)
          user   = result[:user]

          if user.persisted?
            users_by_dn[entry.dn] = user.id
            managers[user]        = result[:manager_dn] if result[:manager_dn]
          end
        end
      end

      raise Net::LDAP::Error.new unless connection.get_operation_result.code == 0

      assign_managers managers, users_by_dn unless skip_function_and_manager?

      import_extra_users_info

      invalid_users = import_extra_users_info? ? remove_invalid_users(start_date) : []

      users = check_state_for_late_changes(users, invalid_users)

      invalid_users.destroy_all if invalid_users.any?
    end

    users
  rescue Net::LDAP::Error
    if try_alternative_ldap?
      connection = alternative_ldap.ldap username, password

      retry
    end

    raise
  end

  private

    def process_entry? entry
      if import_extra_users_info? || entry[email_attribute].present?
        role_names = role_data entry
        roles      = clean_roles Role.list_with_corporate.where(name: role_names)
        data       = trivial_data entry
        user       = find_user data

        if user&.roles.blank? && roles.blank?
          false
        else
          { user: user, roles: roles, data: data }
        end
      end
    end

    def process_entry entry, user:, roles:, data:
      manager_dn = casted_attribute entry, manager_attribute

      data[:manager_id] = nil if manager_dn.blank? && !skip_function_and_manager?

      state = if user
                update_user user: user, data: data, roles: roles

                if user.roles.any?
                  user.saved_changes? ? :updated : :unchanged
                else
                  :deleted
                end
              else
                user = create_user user: user, data: data, roles: roles
                :created
              end

      state = :errored if user.errors.any?

      { user: user, manager_dn: manager_dn, state: state }
    end

    def find_user data
      User.group_list.by_email(data[:email])             ||
        User.without_organization.by_email(data[:email]) ||
        User.list.by_user(data[:user])
    end

    def role_data entry
      entry_roles = entry[roles_attribute].map do |r|
        r&.force_encoding('UTF-8')&.sub(/.*?cn=(.*?),.*/i, '\1')&.to_s
      end

      entry_roles | DEFAULT_LDAP_ROLES
    end

    def trivial_data entry
      {
        user:                casted_attribute(entry, username_attribute),
        name:                casted_attribute(entry, name_attribute),
        last_name:           casted_attribute(entry, last_name_attribute),
        email:               casted_attribute(entry, email_attribute),
        organizational_unit: casted_organizational_unit(entry),
        hidden:              false,
        enable:              true
      }.merge(
        if skip_function_and_manager?
          {}
        else
          { function:  casted_attribute(entry, function_attribute) }
        end
      )
    end

    def casted_attribute entry, attr_name
      attr_name && entry[attr_name].first&.force_encoding('UTF-8')&.to_s
    end

    def casted_organizational_unit entry
      casted_ou = casted_attribute(entry, organizational_unit_attribute)

      casted_ou&.gsub /\Acn=[\w\s]+,/i, ''
    end

    def clean_roles roles
      if roles.all?(&:audited?)
        roles
      elsif roles.group_by(&:organization_id).size == 1
        roles.reject(&:audited?)
      else
        roles.group_by(&:organization_id).map do |organization_id, roles|
          clean_roles roles
        end.flatten
      end
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

      if import_extra_users_info?
        user.assign_attributes data

        user.save validate: false
      else
        user.update data
      end
    end

    def create_user user: nil, data: nil, roles: nil
      data[:organization_roles_attributes] = roles.map do |r|
        { organization_id: r.organization_id, role_id: r.id }
      end.compact

      if import_extra_users_info?
        user = User.new data

        user.save validate: false
      else
        user = User.create data
      end

      user
    end

    def assign_managers managers, users_by_dn
      managers.each do |user, manager_dn|
        manager_id = if users_by_dn[manager_dn] == user.id
                       nil
                     else
                       users_by_dn[manager_dn]
                     end

        user.reload.update manager_id: manager_id
      end
    end

    def skip_function_and_manager?
      @_skip_function_and_manager_setting ||= Current.organization.settings.find_by(
        name: 'skip_function_and_manager_from_ldap_sync'
      )

      value = if @_skip_function_and_manager_setting
                @_skip_function_and_manager_setting.value
              else
                DEFAULT_SETTINGS[:skip_function_and_manager_from_ldap_sync][:value]
              end

      value != '0'
    end

    def check_state_for_late_changes(users, invalid_users)
      users.map! do |u_d|
        unless invalid_users.include? u_d[:user]
          if u_d[:state] == :unchanged && u_d[:user].saved_changes?
            u_d[:state] = :updated
          end

          if (errors = u_d[:user].errors).any?
            u_d[:state]  = :errored
            u_d[:errors] = errors.full_messages.to_sentence
          end
          u_d
        end
      end.compact
    end

    def remove_invalid_users start_date
      User.where(email: nil).
        where('updated_at >= ?', start_date)
    end
end
