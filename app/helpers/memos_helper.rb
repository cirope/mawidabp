module MemosHelper
  def memo_plan_item_field form
    require 'ostruct' unless defined? OpenStruct

    grouped_plan_items = PlanItem.list_unused(@memo.period_id)
                                 .group_by(&:business_unit_type)

    business_unit_types = grouped_plan_items.map do |but, plan_items|
      sorted_plan_items = plan_items.sort_by(&:project)

      OpenStruct.new name: but.name, plan_items: sorted_plan_items
    end

    form.grouped_collection_select :plan_item_id, business_unit_types,
                                   :plan_items, :name, :id, :project_with_dates,
                                   { prompt: true },
                                   { class: 'form-control', disabled: false }
  end

  def required_by_options
    Memo::REQUIRED_BY_OPTIONS.map do |option|
      [option, option]
    end
  end
end
