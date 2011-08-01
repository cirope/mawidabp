module PlansHelper
  def plan_resource_field(form, id = '', inline = true)
    resource_classes = ResourceClass.material_resources

    form.grouped_collection_select(:resource_id, resource_classes, :resources,
      :to_s, :id, :to_s,
      {:prompt => true},
      {
        :class => (:inline_item if inline), :id => "#{id}_resource_id",
        :autofocus => true
      }
    )
  end

  def show_plan_item_info(plan_item)
    show_info(plan_item.status_text, :class => plan_item.status_color)
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
    label = '<h1 class="simple_title" style="margin: .5em 0em;">%s</h1>'

    BusinessUnitType.list.each do |but|
      list << label % show_plan_group_link(but, grouped_plan_items[but])
    end

    list << label % show_plan_group_link(nil, grouped_plan_items[nil])

    content_tag(:ul, raw(list.map { |li| content_tag(:li, raw(li)) }),
      :class => :raw_list, :style => 'font-size: 1.2em;')
  end

  def show_plan_business_unit_type_info
    label = @business_unit_type.try(:name) ||
      t(:'plan.without_business_unit_type')
    link = @plan.new_record? ? new_plan_path : edit_plan_path(@plan)

    content_tag(:h1,
      raw("#{label} - " + link_to(t(:'plan.show_all'), link)))
  end

  def show_plan_group_link(business_unit_type, plan_items)
    label = business_unit_type.try(:name) ||
      t(:'plan.without_business_unit_type')
    parameters = {:business_unit_type => business_unit_type || 'nil'}
    link = @plan.new_record? ?
      new_plan_path(parameters) : edit_plan_path(@plan, parameters)

    raw(link_to_if(params[:clone_from].blank?, label, link) +
        " (#{plan_items.try(:size) || 0})")
  end
end