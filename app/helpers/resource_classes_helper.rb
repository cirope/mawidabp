module ResourceClassesHelper
  def resource_class_type_field(form)
    options = ResourceClass::TYPES.map do |k, v|
      [t("resource_class.type_#{k}"), v]
    end

    form.input :resource_class_type, collection: sort_options_array(options),
      prompt: true, disabled: !form.object.new_record?
  end

  def resource_class_type_text(type)
    content_tag(:span, resource_class_type_name_for(type), :class => :bold)
  end

  def resource_class_type_name_for(type)
    t "resource_class.type_#{ResourceClass::TYPES.invert[type]}"
  end
end
