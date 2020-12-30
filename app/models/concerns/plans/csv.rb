module Plans::Csv
  extend ActiveSupport::Concern

  def to_csv business_unit_type: nil
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers

      csv_put_business_unit_types_on csv, business_unit_type
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename
    I18n.t 'plans.csv.csv_name', period: period.name
  end

  private
    def csv_order
      [
        'order_number',
        'status',
        'business_unit_id',
        'project',
        'tags',
        'start',
        'end',
        ('scope' if SHOW_REVIEW_EXTRA_ATTRIBUTES),
        ('risk_exposure' if SHOW_REVIEW_EXTRA_ATTRIBUTES),
        'human_resource_units',
        'material_resource_units',
        'total_resource_units'
      ].compact
    end

    def csv_headers
      csv_order.map do |col_name|
        PlanItem.human_attribute_name(col_name)
      end
    end

    def csv_put_business_unit_types_on csv, business_unit_type
      if business_unit_type
        csv_rows csv, business_unit_type
      else
        business_unit_types.each do |business_unit_type|
          csv_rows csv, business_unit_type
        end
      end
    end

    def csv_rows csv, business_unit_type
      plan_items = Array(grouped_plan_items[business_unit_type]).sort

      if plan_items.present?
        plan_items.each do |plan_item|
          csv << [
            plan_item.order_number,
            plan_item.status_text(long: false),
            plan_item.business_unit&.name || '',
            plan_item.project,
            plan_item.tags.map(&:to_s).join(';'),
            I18n.l(plan_item.start, format: :default),
            I18n.l(plan_item.end, format: :default),
            (plan_item.scope if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            (plan_item.risk_exposure if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            '%.2f' % plan_item.human_units,
            '%.2f' % plan_item.material_units,
            '%.2f' % plan_item.units
          ].compact
        end
      end
    end
end
