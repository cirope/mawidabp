module UsersHelper
  def show_user_with_email_as_abbr(user)
    content_tag(:abbr, h(user.user), :title => user.email)
  end

  def user_language_field(form, disabled: false)
    options = AVAILABLE_LOCALES.map do |lang|
      [t("lang.#{lang}"), lang.to_s]
    end.sort{ |a, b| a[0] <=> b[0] }

   form.input :language, collection: options, prompt: true, input_html: { disabled: disabled }
  end

  def user_info user
    if user.organizations.blank?
      show_info t('user.without_organization'), class: :red
    elsif user.notes.present?
      show_info user.notes
    end
  end

  def user_organizations organization_role
    group = if current_organization
              current_organization.group
            else
              Group.find_by_admin_hash params[:hash]
            end

    organizations = if NOTIFY_NEW_ADMIN
                      Organization.list_with_selected group, organization_role&.organization
                    else
                      Organization.with_group group
                    end

    sorted_options_array_for organizations, :name, :id
  end

  def user_organization_roles
    @user.organization_roles.select { |o_r| o_r.new_record? || o_r.marked_for_destruction? } |
      @user.organization_roles.for_group(current_organization.group_id)
  end

  def roles_for organization_role
    roles = if organization_role.organization_id
              Role.list_by_organization organization_role.organization_id
            else
              Role.none
            end

    sorted_options_array_for roles, :name, :id
  end

  def user_roles_path
    if params[:hash].present?
      users_registration_roles_path hash: params[:hash]
    else
      users_roles_path
    end
  end

  def show_import_from_ldap?
    setting = current_organization.settings.find_by name: 'hide_import_from_ldap'
    result  = (setting ? setting.value : DEFAULT_SETTINGS[:hide_import_from_ldap][:value]) != '0'

    !result || can_perform?(:edit, :approval)
  end

  def business_unit_types
    BusinessUnitType.list
  end
end
