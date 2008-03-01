module ResourceClassesHelper
  def resource_class_type_field(form, inline = true)
    options = ResourceClass::TYPES.map do |k, v|
      [t("resource_class.type_#{k}"), v]
    end

    form.select :resource_class_type, sort_options_array(options),
      {:prompt => true},
      {:class => (:inline_item if inline),
      :disabled => !form.object.new_record?}
  end

  def resource_class_type_text(type)
    content_tag(:span, resource_class_type_name_for(type), :class => :bold)
  end

  def resource_class_type_name_for(type)
    t "resource_class.type_#{ResourceClass::TYPES.invert[type]}"
  end
end