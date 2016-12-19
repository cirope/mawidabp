module PlansHelper
  def plan_resource_field form, id = '', inline = true
    form.input :resource_id, collection: ResourceClass.list, as: :grouped_select,
      group_method: :resources, label: false, prompt: true, input_html: {
      id: "#{id}_resource_id", autofocus: true
    }
  end

  def show_plan_item_info plan_item
    show_info plan_item.status_text, class: [plan_item.status_color, 'media-object'].join(' ')
  end

  def plan_items_for_selected_business_unit_type
    business_unit_type = params[:business_unit_type].to_i > 0 ?
      params[:business_unit_type].to_i : nil

    @plan.plan_items.select do |pi|
      pi.business_unit.try(:business_unit_type_id) == business_unit_type
    end.sort
  end

  def show_plan_business_unit_type_list
    list = []
    grouped_plan_items = @plan.grouped_plan_items
    label = '<h4>%s</h4>'

    (BusinessUnitType.list + [nil]).each do |but|
      list << label % show_plan_group_link(but, grouped_plan_items[but])
    end

    content_tag(:ul, raw((list.map { |li| content_tag(:li, raw(li)) }).join('')))
  end

  def show_plan_business_unit_type_info
    label = @business_unit_type.try(:name) ||
      t('plan.without_business_unit_type')
    link = @plan.new_record? ? new_plan_path : edit_plan_path(@plan)

    content_tag(:h4,
      raw("#{label} - " + link_to(t('plan.show_all'), link)))
  end

  def show_plan_group_link(business_unit_type, plan_items)
    label = business_unit_type.try(:name) ||
      t('plan.without_business_unit_type')
    parameters = {:business_unit_type => business_unit_type || 'nil'}
    link = @plan.new_record? ?
      new_plan_path(parameters) : edit_plan_path(@plan, parameters)

    raw(link_to_if(params[:clone_from].blank?, label, link) +
        " (#{plan_items.try(:size) || 0})")
  end
end
