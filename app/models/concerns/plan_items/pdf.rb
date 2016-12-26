module PlanItems::Pdf
  extend ActiveSupport::Concern

  def add_resource_data pdf, show_description = true
    row_data = []

    pdf.move_down PDF_FONT_SIZE

    put_description_on pdf if show_description

    resource_utilizations.each do |resource_utilization|
      row_data << row_data_for(resource_utilization)
    end

    row_data << total_row_data

    put_resource_utilizations_table_on pdf, row_data if row_data.size > 1
  end

  private

    def currency_mask
      "#{I18n.t('number.currency.format.unit')}%.2f"
    end

    def column_order
      [
        ['resource_id', 40],
        ['units', 20],
        ['cost_per_unit', 20],
        ['cost', 20]
      ]
    end

    def column_headers
      column_order.map do |col_name, col_with|
        ResourceUtilization.human_attribute_name col_name
      end
    end

    def column_widths pdf
      column_order.map { |col_name, col_with| pdf.percent_width(col_with) }
    end

    def put_description_on pdf
      text  = "<b>(#{order_number})</b> #{project}"
      text += " (#{business_unit.name})" if business_unit

      pdf.text text, font_size: PDF_FONT_SIZE, inline_format: true
      pdf.move_down (PDF_FONT_SIZE * 0.5).round
    end

    def put_resource_utilizations_table_on pdf, row_data
      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options column_widths(pdf)

        pdf.table(row_data.insert(0, column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def row_data_for resource_utilization
      [
        resource_utilization.resource.resource_name,
        resource_utilization.units,
        currency_mask % resource_utilization.cost_per_unit,
        currency_mask % resource_utilization.cost
      ]
    end

    def total_row_data
      ['', '', '', "<b>#{currency_mask % cost}</b>"]
    end
end
