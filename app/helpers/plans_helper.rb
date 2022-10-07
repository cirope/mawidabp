module PlansHelper
  def plan_resource_field form, id = nil
    form.input :resource_id,
      collection: ResourceClass.list,
      as: :grouped_select,
      group_method: :resources,
      label: false,
      prompt: true,
      input_html: {
        id: "#{id}_resource_id", autofocus: form.object.new_record?
      }
  end

  def show_plan_item_info plan_item
    if Current.conclusion_pdf_format == 'pat'
      show_info plan_item.status_text_pat(long: false), class: [plan_item.status_color_pat(), 'media-object'].join(' ')
    else
      show_info plan_item.status_text(on: plan_status_info_date), class: [plan_item.status_color(on: plan_status_info_date), 'media-object'].join(' ')
    end
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
      pi.business_unit&.business_unit_type_id == business_unit_type ||
        pi.auxiliar_business_unit_types.any? { |auxbu| auxbu.business_unit_type_id == business_unit_type }
    end.sort
  end

  def plan_business_unit_type_list
    grouped_plan_items = @plan.grouped_plan_items

    BusinessUnitType.allowed_business_unit_types.map do |but|
      [but, Array(grouped_plan_items[but])]
    end
  end

  def count_plan_items_for_allowed_business_unit_types
    BusinessUnitType.allowed_business_unit_types.map do |but|
      count = @plan.plan_items.select do |pi|
        pi.business_unit&.business_unit_type_id == but.try(:id) ||
          pi.auxiliar_business_unit_types.any? { |auxbu| auxbu.business_unit_type_id == but.try(:id) }
      end.count

      [but, count]
    end
  end

  def link_to_plan_business_unit_type but, &block
    html_classes  = 'list-group-item list-group-item-action'
    html_classes << ' disabled' if @plan.new_record?

    options = { class: html_classes }

    if @plan.persisted?
      link_to edit_plan_path(@plan, business_unit_type: but || 'nil'), options, &block
    else
      link_to '#', options, &block
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

  def plan_status_info_date
    date = Timeliness.parse params[:until], :date if params[:until].present?

    date || Time.zone.today
  end

  def plan_status_date
    date = Timeliness.parse params[:until], :date if params[:until].present?

    date || @plan.period&.end || Time.zone.today
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
        [@plan, _ts: Time.now.to_i, format: :pdf],
        class: 'dropdown-item'
      ),
      link_to(
        t('plans.download_detailed_plan'),
        [@plan, include_details: 1, _ts: Time.now.to_i, format: :pdf],
        class: 'dropdown-item'
      ),
      link_to(
        t('plans.download_business_unit_type_plan_csv'),
        [@plan, include_details: 1, _ts: Time.now.to_i, format: :csv],
        class: 'dropdown-item'
      )
    ]

    options += pat_download_options if Current.conclusion_pdf_format == 'pat'

    if @business_unit_type
      options | business_unit_type_download_options
    else
      options
    end
  end

  private

    def pat_download_options
      [
        link_to(
          t('plans.download_progress_report_with_statuses_pat'),
          [@plan, prs: 1, _ts: Time.now.to_i, format: :csv],
          class: 'dropdown-item'
        ),
        link_to(
          t('plans.download_progress_report_in_hours_of_work_pat'),
          [@plan, prh: 1,  _ts: Time.now.to_i, format: :csv],
          class: 'dropdown-item'
        )
      ]
    end

    def business_unit_type_planned_items
      date  = plan_status_date
      items = Array(@plan.grouped_plan_items[@business_unit_type])

      items.select { |plan_item| plan_item.start <= date }
    end

    def business_unit_type_download_options
      [
        link_to(
          t('plans.download_business_unit_type_plan', business_unit_type: @business_unit_type.name),
          [@plan, business_unit_type: @business_unit_type.id, _ts: Time.now.to_i, format: :pdf],
          class: 'dropdown-item'
        ),
        link_to(
          t('plans.download_detailed_business_unit_type_plan', business_unit_type: @business_unit_type.name),
          [@plan, include_details: 1, business_unit_type: @business_unit_type.id, _ts: Time.now.to_i, format: :pdf],
          class: 'dropdown-item'
        ),
        link_to(
          t('plans.download_detailed_business_unit_type_plan_csv', business_unit_type: @business_unit_type.name),
          [@plan, include_details: 1, business_unit_type: @business_unit_type.id, _ts: Time.now.to_i, format: :csv],
          class: 'dropdown-item'
        )
      ]
    end

    def count_plan_items_for_business_unit_types
      @plan
    end
end
