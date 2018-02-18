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
    show_info plan_item.status_text(on: plan_status_date),
      class: [plan_item.status_color(on: plan_status_date), 'media-object'].join(' ')
  end

  def plan_cost
    units = if params[:business_unit_type].present?
              @plan.estimated_amount params[:business_unit_type], on: plan_status_date
            else
              @plan.units on: plan_status_date
            end

    '%.2f' % units
  end

  def plan_material_cost
    units = if params[:business_unit_type].present?
              @plan.estimated_material_amount params[:business_unit_type], on: plan_status_date
            else
              @plan.material_units on: plan_status_date
            end

    '%.2f' % units
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

  def render_business_unit_type_plan_items
    render(
      'business_unit_type_plan_items',
      business_unit_type:        @business_unit_type,
      plan_items:                business_unit_type_planned_items,
      show_resource_utilization: false
    )
  end

  def plan_status_date
    date = Timeliness.parse params[:until], :date if params[:until].present?

    date || Time.zone.today
  end

  def should_fetch_resources_for? plan_item
    is_valid = plan_item.errors.empty?
    resources_are_unchanged = plan_item.resource_utilizations.all? do |ru|
      ru.persisted? && ru.errors.empty? && !ru.changed?
    end

    is_valid && resources_are_unchanged
  end

  def plan_download_options
    options = [
      link_to(
        t('plans.download_global_plan'),
        [@plan, _ts: Time.now.to_i, format: :pdf]
      ),
      link_to(
        t('plans.download_detailed_plan'),
        [@plan, include_details: 1, _ts: Time.now.to_i, format: :pdf]
      )
    ]

    if @business_unit_type
      options | business_unit_type_download_options
    else
      options
    end
  end

  private

    def business_unit_type_planned_items
      date  = plan_status_date
      items = Array(@plan.grouped_plan_items[@business_unit_type])

      items.select { |plan_item| plan_item.start <= date }
    end

    def business_unit_type_download_options
      [
        link_to(
          t('plans.download_business_unit_type_plan', business_unit_type: @business_unit_type.name),
          [@plan, business_unit_type: @business_unit_type.id, _ts: Time.now.to_i, format: :pdf]
        ),
        link_to(
          t('plans.download_detailed_business_unit_type_plan', business_unit_type: @business_unit_type.name),
          [@plan, include_details: 1, business_unit_type: @business_unit_type.id, _ts: Time.now.to_i, format: :pdf]
        )
      ]
    end
end
