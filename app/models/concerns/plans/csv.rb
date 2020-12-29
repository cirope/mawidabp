module Plans::Csv
  extend ActiveSupport::Concern

  def to_csv business_unit_type: nil
    options            = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }
    grouped_plan_items = self.grouped_plan_items

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_title
      csv << csv_period
      csv << csv_headers

      csv_rows(business_unit_type).each { |row| csv << row }
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename
    I18n.t 'plans.csv.csv_name', period: period.name
  end

  private
    def csv_title
      [I18n.t('plans.csv.title')]
    end

    def csv_period
      period_label = I18n.t 'plans.period.title', name: period.name
      range_label  = I18n.t 'plans.period.range', **{
        from_date: I18n.l(period.start, format: :long),
        to_date:   I18n.l(period.end,   format: :long)
      }

      [period_label, range_label]
    end

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

    def csv_rows business_unit_type
      plan_items = Array(grouped_plan_items[business_unit_type]).sort
      rows       = []

      plan_items.each do |plan_item|
        rows << [
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

      rows
    end
end
