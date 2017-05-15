module PlansHelper
  def plan_resource_field form, id = nil
    form.input :resource_id,
      collection: ResourceClass.list,
      as: :grouped_select,
      group_method: :resources,
      label: false,
      prompt: true,
      input_html: {
        id: "#{id}_resource_id", autofocus: true
      }
  end

  def show_plan_item_info plan_item
    show_info plan_item.status_text,
      class: [plan_item.status_color, 'media-object'].join(' ')
  end

  def plan_item_path plan_item
    if plan_item.persisted?
      edit_plan_plan_item_path @plan, plan_item
    else
      new_plan_plan_item_path @plan
    end
  end

  def plan_items_for_selected_business_unit_type
    business_unit_type = params[:business_unit_type].to_i > 0 ?
      params[:business_unit_type].to_i : nil

    @plan.plan_items.select do |pi|
      pi.business_unit&.business_unit_type_id == business_unit_type
    end.sort
  end

  def plan_business_unit_type_list
    grouped_plan_items = @plan.grouped_plan_items

    (BusinessUnitType.list + [nil]).map do |but|
      [but, Array(grouped_plan_items[but])]
    end
  end

  def link_to_plan_business_unit_type but, &block
    if @plan.persisted?
      link_to edit_plan_path(@plan, business_unit_type: but || 'nil'), &block
    else
      link_to '#', &block
    end

  end
end
