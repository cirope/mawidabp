module PlansHelper
  def plan_resource_field(form, id = '', inline = true)
    resource_classes = ResourceClass.material_resources

    form.grouped_collection_select(:resource_id, resource_classes, :resources,
      :to_s, :id, :to_s,
      {:prompt => true},
      {:class => (:inline_item if inline), :id => "#{id}_resource_id"})
  end

  def show_plan_item_info(plan_item)
    show_info(plan_item.status_text, :class => plan_item.status_color)
  end
end