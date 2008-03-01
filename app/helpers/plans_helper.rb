module PlansHelper
  def plan_resource_field(form, id = '', inline = true)
    resource_classes = ResourceClass.material_resources

    form.grouped_collection_select(:resource_id, resource_classes, :resources,
      :to_s, :id, :to_s,
      {:prompt => true},
      {:class => (:inline_item if inline), :id => "#{id}_resource_id"})
  end

  def show_plan_item_info(plan_item)
    info = nil
    html_class = nil

    if plan_item.try(:review).try(:has_final_review?)
      info = t(:'plan.item_status.concluded')
      html_class = :green
    elsif plan_item.try(:review)
      if plan_item.end >= Date.today
        info = t(:'plan.item_status.executing_in_time')
        html_class = :gray
      else
        info = t(:'plan.item_status.executing_overtime')
        html_class = :yellow
      end
    elsif !plan_item.try(:review) && plan_item.try(:business_unit)
      if plan_item.try(:start) && plan_item.start < Date.today
        info = t(:'plan.item_status.delayed')
        html_class = :red
      end
    end

    show_info(info, :class => html_class)
  end
end