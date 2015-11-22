module RolesHelper
  def role_type_field(form)
    options = Role::TYPES.map { |k, v| [t("role.type_#{k}"), v] }

    form.input :role_type, collection: sort_options_array(options), prompt: true
  end

  def role_type_text(type, strong = nil)
    tag = strong ? :strong : :span
    content_tag(tag, role_type_name_for(type))
  end

  def role_type_name_for(type)
    t "role.type_#{Role::TYPES.invert[type]}"
  end
end
