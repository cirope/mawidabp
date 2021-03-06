module DynamicFormHelper
  def link_to_add_fields(name, form, association, partial = nil, data = {}, locals = {})
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    template = form.fields_for(association, new_object, child_index: id) do |f|
      render (partial || association.to_s.singularize), locals.merge(f: f, parent: form)
    end

    link_to(
      name, '#', class: 'btn btn-outline-secondary btn-sm', title: name, data: {
        id: id,
        association: association,
        dynamic_form_event: 'addNestedItem',
        dynamic_template: template.gsub("\n", ''),
        show_tooltip: true
      }.merge(data)
    )
  end

  def link_to_insert_field(form, source = nil)
    link_to(
      icon('fas', 'indent'), '#', data: {
        'id' => form.object.object_id,
        'dynamic-form-event' => 'insertNestedItem',
        'dynamic-source' => "[data-association='#{(source || form.object.class.to_s.tableize)}']",
        'show-tooltip' => true
      }
    )
  end

  def link_to_add_item(name, new_object, partial)
    id = new_object.object_id
    template = render(partial, item: new_object)

    link_to(
      name, '#', class: 'btn btn-outline-secondary btn-sm', title: name, data: {
        'id' => id,
        'dynamic-form-event' => 'addNestedItem',
        'dynamic-template' => template.gsub("\n", ''),
        'show-tooltip' => true
      }
    )
  end

  def link_to_remove_nested_item(form)
    new_record = form.object.new_record?
    out = ''
    destroy = form.object.marked_for_destruction? ? 1 : 0

    out << form.hidden_field(:_destroy, class: 'destroy', value: destroy, id: "destroy_hidden_#{form.object.id}") unless new_record
    out << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => ".#{form.object.class.name.underscore}",
        'dynamic-form-event' => (new_record ? 'removeItem' : 'hideItem'),
        'show-tooltip' => true
      }
    )

    raw out
  end

  def link_to_remove_support_file(form)
    id         = form.object.object_id
    out        = ''

    if form.object.persisted? && form.object.support?
      out << form.hidden_field(
        :remove_support,
        class: 'destroy',
        value: 0,
        id: "remove_support_hidden_#{form.object.id}"
      )
      out << link_to(
        icon('fas', 'times'), '#',
        title: t('label.delete'),
        data: {
          'dynamic-target' => "#control_objective_support_#{id}",
          'dynamic-form-event' => 'hideItemAttr',
        }
      )
    end

    raw out
  end

  def link_to_remove_child_item(form)
    link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => '.child',
        'dynamic-form-event' => 'removeItem',
        'show-tooltip' => true
      }
    )
  end
end
