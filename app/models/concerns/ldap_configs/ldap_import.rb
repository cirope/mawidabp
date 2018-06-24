module LdapConfigs::LDAPImport
  extend ActiveSupport::Concern

  def import username, password
    ldap        = ldap username, password
    ldap_filter = Net::LDAP::Filter.construct filter
    users_by_dn = {}
    managers    = {}
    users       = []

    User.transaction do
      ldap.search(base: basedn, filter: ldap_filter) do |entry|
        if entry[email_attribute].present?
          users << (result = process_entry entry)
          user   = result[:user]

          if user.persisted?
            users_by_dn[entry.dn] = user.id
            managers[user]        = result[:manager_dn] if result[:manager_dn]
          end
        end
      end

      raise Net::LDAP::Error.new unless ldap.get_operation_result.code == 0

      assign_managers managers, users_by_dn

      users = check_state_for_late_changes(users)
    end

    users
  end

  private

    def process_entry entry
      role_names = role_data entry
      manager_dn = casted_attribute entry, manager_attribute
      data       = trivial_data entry
      roles      = clean_roles Role.list_with_corporate.where(name: role_names)
      user       = User.by_email data[:email]

      data[:manager_id] = nil if manager_dn.blank?

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

    def role_data entry
      entry_roles = entry[roles_attribute].map do |r|
        r&.force_encoding('UTF-8')&.sub(/.*?cn=(.*?),.*/i, '\1')&.to_s
      end

      entry_roles | DEFAULT_LDAP_ROLES
    end

    def trivial_data entry
      {
        user:      casted_attribute(entry, username_attribute),
        name:      casted_attribute(entry, name_attribute),
        last_name: casted_attribute(entry, last_name_attribute),
        email:     casted_attribute(entry, email_attribute),
        function:  casted_attribute(entry, function_attribute),
        hidden:    false,
        enable:    true
      }
    end

    def casted_attribute entry, attr_name
      attr_name && entry[attr_name].first&.force_encoding('UTF-8')&.to_s
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
          { id: o_r.id, _destroy: '1' } if o_r.organization_id == Current.organization_id
        end
      end
      data[:organization_roles_attributes] = new_roles.compact + removed_roles.compact

      user.update data
    end

    def create_user user: nil, data: nil, roles: nil
      data[:organization_roles_attributes] = roles.map do |r|
        { organization_id: r.organization_id, role_id: r.id }
      end.compact

      user = User.create data
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

    def check_state_for_late_changes(users)
      users.map do |u_d|
        if u_d[:state] == :unchanged && u_d[:user].saved_changes?
          u_d[:state] = :updated
        end

        if (errors = u_d[:user].errors).any?
          u_d[:state]  = :errored
          u_d[:errors] = errors.full_messages.to_sentence
        end

        u_d
      end
    end
end
