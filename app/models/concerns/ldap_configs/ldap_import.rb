module LdapConfigs::LDAPImport
  extend ActiveSupport::Concern

  def import username, password
    ldap        = ldap username, password
    filter      = Net::LDAP::Filter.eq 'CN', '*'
    users_by_dn = {}
    managers    = {}
    users       = []

    User.transaction do
      ldap.search(base: basedn, filter: filter) do |entry|
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
    end

    users
  end

  private

    def process_entry entry
      role_names = entry[roles_attribute].map { |r| r.try(:force_encoding, 'UTF-8').sub(/.*?cn=(.*?),.*/i, '\1') }
      manager_dn = manager_attribute && entry[manager_attribute].first.try(:force_encoding, 'UTF-8')
      data       = trivial_data entry
      roles      = clean_roles Role.list.where(name: role_names)
      user       = User.where(email: data[:email]).take
      new        = !user

      if user
        update_user user: user, data: data, roles: roles
      else
        user = create_user user: user, data: data, roles: roles
      end

      { user: user, manager_dn: manager_dn, new: new }
    end

    def trivial_data entry
      {
        user:      entry[username_attribute].first.try(:force_encoding, 'UTF-8'),
        name:      entry[name_attribute].first.try(:force_encoding, 'UTF-8'),
        last_name: entry[last_name_attribute].first.try(:force_encoding, 'UTF-8'),
        email:     entry[email_attribute].first.try(:force_encoding, 'UTF-8'),
        function:  function_attribute && entry[function_attribute].first.try(:force_encoding, 'UTF-8'),
        enable:    true
      }
    end

    def clean_roles roles
      if roles.all?(&:audited?)
        roles
      else
        roles.reject(&:audited?)
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
          { id: o_r.id, _destroy: '1' } if o_r.organization_id == Organization.current_id
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
        user.update! manager_id: users_by_dn[manager_dn]
      end
    end
end
