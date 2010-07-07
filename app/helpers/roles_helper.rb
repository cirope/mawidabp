module RolesHelper
  def role_type_field(form, inline = true)
    options = Role::TYPES.map { |k, v| [t("role.type_#{k}"), v] }

    form.select :role_type, sort_options_array(options),
      {:prompt => true},
      {:class => "no_observe_changes #{:inline_item if inline}"}
  end

  def role_type_text(type, html_class = :bold)
    content_tag(:span, role_type_name_for(type), :class => html_class)
  end

  def role_type_name_for(type)
    t "role.type_#{Role::TYPES.invert[type]}"
  end
end