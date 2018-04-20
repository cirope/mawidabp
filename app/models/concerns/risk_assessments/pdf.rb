module RiskAssessments::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header organization
    pdf.add_title *pdf_title
    pdf.add_description_item *pdf_period

    pdf.move_down PDF_FONT_SIZE
    pdf.add_title name, (PDF_FONT_SIZE * 1.25).round

    put_risk_assessment_items_on pdf

    pdf.custom_save_as pdf_name, RiskAssessment.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, RiskAssessment.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, RiskAssessment.table_name, id
  end

  def pdf_name
    I18n.t 'risk_assessments.pdf.pdf_name',
      name: name.sanitized_for_filename.downcase
  end

  private

    def pdf_title
      ["#{I18n.t('risk_assessments.pdf.title')}\n", (PDF_FONT_SIZE * 1.5).round, :center]
    end

    def pdf_period
      period_label = I18n.t 'risk_assessments.pdf.period.title', name: period.name
      range_label  = I18n.t 'risk_assessments.pdf.period.range', {
        from_date: I18n.l(period.start, format: :long),
        to_date:   I18n.l(period.end,   format: :long)
      }

      [period_label, range_label, 0, false]
    end

    def put_risk_assessment_items_on pdf
      row_data = risk_assessment_item_rows

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
    end

    def risk_assessment_item_rows
      risk_assessment_items.map do |risk_assessment_item|
        [
          risk_assessment_item.name,
          risk_assessment_item.business_unit_type.to_s,
          risk_assessment_item.business_unit.to_s,
          risk_assessment_item.risk
        ]
      end
    end

    def column_order
      [
        [RiskAssessmentItem.human_attribute_name('name'), 30],
        [BusinessUnitType.model_name.human, 25],
        [RiskAssessmentItem.human_attribute_name('business_unit'), 35],
        [RiskAssessmentItem.human_attribute_name('risk'), 10]
      ]
    end

    def column_headers
      column_order.map { |col_name, _| "<b>#{col_name}</b>" }
    end

    def column_widths pdf
      column_order.map { |col_name, col_with| pdf.percent_width(col_with) }
    end
end
