module Reviews::WeaknessesBrief
  extend ActiveSupport::Concern

  def put_weaknesses_brief_table pdf, finals
    column_data = weaknesses_brief_column_data finals

    if column_data.present?
      widths        = weaknesses_brief_column_widths pdf
      data          = column_data.insert 0, weaknesses_brief_column_headers
      table_options = pdf.default_table_options widths

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data, table_options do
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

  private

    def weaknesses_brief_column_data finals
      findings = finals ? final_weaknesses : weaknesses

      [
        [
          I18n.t('review.new_weaknesses'),
          self.class.risks.to_a.reverse.map do |risk, value|
            findings.not_revoked.where(risk: value, repeated_of_id: nil).count
          end
        ].flatten,
        [
          I18n.t('review.repeated_weaknesses'),
          self.class.risks.to_a.reverse.map do |risk, value|
            findings.not_revoked.where(risk: value).where.not(repeated_of_id: nil).count
          end
        ].flatten
      ]
    end

    def weaknesses_brief_column_widths pdf
      columns_count = self.class.risks.size.next

      columns_count.times.map do
        pdf.percent_width 100.0 / columns_count
      end
    end

    def weaknesses_brief_column_headers
      [
        '',
        self.class.risks.to_a.reverse.map do |risk, value|
          "<b>#{I18n.t "risk_types.#{risk}"}</b>"
        end
      ].flatten
    end
end
