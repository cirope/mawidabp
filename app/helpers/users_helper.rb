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
    options = AVAILABLE_LOCALES.map do
      |lang| [t("lang.#{lang}"), lang.to_s]
    end.sort{ |a, b| a[0] <=> b[0] }

    form.input :language, collection: options
  end

  def user_organizations_field(form, id = nil )
    group = current_organization ? current_organization.group :
      Group.find_by_admin_hash(params[:hash])

    form.input :organization_id, collection: sorted_options_array_for(
      Organization.list_for_group(group), :name, :id), prompt: true,
      label: false, input_html: { id: "#{id}_organization_id" }
  end

  def user_weaknesses_links(user)
    filtered_weaknesses = user.weaknesses.for_current_organization.finals(
      false).not_incomplete
    pending_count = filtered_weaknesses.with_pending_status.count
    complete_count = filtered_weaknesses.count - pending_count

    pending_link = link_to_unless(pending_count == 0,
      textilize_without_paragraph(
        t('user.weaknesses.pending', :count => pending_count)
      ), findings_path(:completed => 'incomplete', :user_id => user.id)
    )
    complete_link = link_to_unless(complete_count == 0,
      textilize_without_paragraph(
        t('user.weaknesses.complete', :count => complete_count)
      ), findings_path(:completed => 'complete', :user_id => user.id)
    )

    raw("#{pending_link} | #{complete_link}")
  end
end
