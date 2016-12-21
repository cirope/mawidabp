module UsersHelper
  def show_user_with_email_as_abbr(user)
    content_tag(:abbr, h(user.user), :title => user.email)
  end

  def user_language_field(form)
    options = AVAILABLE_LOCALES.map do |lang|
      [t("lang.#{lang}"), lang.to_s]
    end.sort{ |a, b| a[0] <=> b[0] }

   form.input :language, collection: options, prompt: true
  end

  def user_info user
    if user.organizations.blank?
      show_info t('user.without_organization'), class: :red
    elsif user.notes.present?
      show_info user.notes
    end
  end

  def user_organizations
    group = current_organization ?
      current_organization.group :
      Group.find_by_admin_hash(params[:hash])

    sorted_options_array_for Organization.with_group(group), :name, :id
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
end
