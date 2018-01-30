module Plans::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = nil, include_details: true, business_unit_type: nil
    pdf                = Prawn::Document.create_generic_pdf :landscape
    grouped_plan_items = self.grouped_plan_items

    pdf.add_generic_report_header organization
    pdf.add_title *pdf_title
    pdf.add_description_item *pdf_period

    put_business_unit_types_on pdf, business_unit_type, include_details

    pdf.custom_save_as pdf_name, Plan.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, Plan.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, Plan.table_name, id
  end

  def pdf_name
    I18n.t 'plans.pdf.pdf_name', period: period.name
  end

  private

    def pdf_title
      ["#{I18n.t('plans.pdf.title')}\n", (PDF_FONT_SIZE * 1.5).round, :center]
    end

    def pdf_period
      period_label = I18n.t 'plans.period.title', name: period.name
      range_label  = I18n.t 'plans.period.range', {
        from_date: I18n.l(period.start, format: :long),
        to_date:   I18n.l(period.end,   format: :long)
      }

      [period_label, range_label, 0, false]
    end

    def column_order
      [
        ['order_number', 6],
        ['status', 6],
        ['business_unit_id', 16],
        ['project', 20],
        ['tags', 7],
        ['start', 7.5],
        ['end', 7.5],
        ['human_resource_units', 10],
        ['material_resource_units', 10],
        ['total_resource_units', 10]
      ]
    end

    def column_headers
      column_order.map do |col_name, col_with|
        "<b>#{PlanItem.human_attribute_name(col_name)}</b>"
      end
    end

    def column_widths pdf
      column_order.map { |col_name, col_with| pdf.percent_width(col_with) }
    end

    def business_unit_types
      BusinessUnitType.list + [nil]
    end

    def put_business_unit_types_on pdf, business_unit_type, include_details
      if business_unit_type
        put_business_unit_type_plan_items_on pdf, business_unit_type,
          include_details
      else
        business_unit_types.each do |business_unit_type|
          put_business_unit_type_plan_items_on pdf, business_unit_type,
            include_details
        end
      end
    end

    def put_business_unit_type_plan_items_on pdf, business_unit_type, include_details
      plan_items = Array(grouped_plan_items[business_unit_type]).sort

      if plan_items.present?
        put_plan_items_on pdf, plan_items, business_unit_type, include_details
      end
    end

    def put_plan_items_on pdf, plan_items, business_unit_type, include_details
      row_data   = []
      total_cost = 0.0

      put_business_unit_type_title_on pdf, business_unit_type

      plan_items.each do |plan_item|
        total_resource_text  = '%.2f' % plan_item.units
        total_cost          += plan_item.units

        row_data << row_data_for(plan_item, total_resource_text)
      end

      row_data << total_row_data(total_cost)

      put_plan_items_table_on pdf, row_data

      if include_details && has_resources?(plan_items)
        put_plan_items_details_table_on pdf, plan_items
      end
    end

    def put_business_unit_type_title_on pdf, business_unit_type
      title = business_unit_type&.name || I18n.t('plans.without_business_unit_type')

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.25).round
    end

    def row_data_for plan_item, total_resource_text
      [
        plan_item.order_number,
        plan_item.status_text(long: false),
        plan_item.business_unit&.name || '',
        plan_item.project,
        plan_item.tags.map(&:to_s).join(';'),
        I18n.l(plan_item.start, format: :default),
        I18n.l(plan_item.end, format: :default),
        '%.2f' % plan_item.human_units,
        '%.2f' % plan_item.material_units,
        total_resource_text
      ]
    end

    def total_row_data total_cost
      [
        '', '', '', '', '', '', '', '', '',
        "<b>#{'%.2f' % total_cost}</b>"
      ]
    end

    def put_plan_items_table_on pdf, row_data
      pdf.move_down PDF_FONT_SIZE

      if row_data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options column_widths(pdf)

          pdf.table row_data.insert(0, column_headers), table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end

      pdf.text "\n#{I18n.t('plans.item_status.note')}", font_size: (PDF_FONT_SIZE * 0.75).round
    end

    def has_resources? plan_items
      plan_items.any? { |pi| pi.resource_utilizations.present? }
    end

    def put_plan_items_details_table_on pdf, plan_items
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title I18n.t('plans.pdf.resource_utilization'), (PDF_FONT_SIZE * 1.1).round

      plan_items.each do |plan_item|
        if plan_item.resource_utilizations.present?
          plan_item.add_resource_data pdf
        end
      end
    end
end
