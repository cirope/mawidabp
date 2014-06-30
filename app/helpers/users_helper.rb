module UsersHelper
  def show_user_with_email_as_abbr(user)
    content_tag(:abbr, h(user.user), :title => user.email)
  end

  def user_resource_field(form)
    resource_classes = ResourceClass.human_resources

    form.input :resource_id, collection: resource_classes, as: :grouped_select,
      group_method: :resources, prompt: true, label: User.human_attribute_name('resource')
  end

  def user_language_field(form)
    options = AVAILABLE_LOCALES.map do |lang|
      [t("lang.#{lang}"), lang.to_s]
    end.sort{ |a, b| a[0] <=> b[0] }

   form.input :language, collection: options, prompt: true
  end

  def user_organizations_field(form, id = nil )
    group = current_organization ? current_organization.group :
      Group.find_by_admin_hash(params[:hash])

    form.input :organization_id, collection: sorted_options_array_for(
      Organization.with_group(group), :name, :id), prompt: true,
      label: false, input_html: { id: "#{id}_organization_id" }
  end

  def user_organization_roles
    @user.organization_roles.select { |o_r| o_r.new_record? || o_r.marked_for_destruction? } |
      @user.organization_roles.for_group(current_organization.group_id)
  end
end
