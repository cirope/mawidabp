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
        new_weaknesses_row(findings),
        repeated_weaknesses_row(findings),
        total_weaknesses_row(findings)
      ]
    end

    def new_weaknesses_row findings
      counts = new_weaknesses_counts(findings).map do |c|
        { content: c.to_s, align: :center }
      end

      [
        I18n.t('review.new_weaknesses'),
        counts,
        {
          content: "<b>#{new_weaknesses_counts(findings).sum}</b>",
          align: :center
        }
      ].flatten
    end

    def repeated_weaknesses_row findings
      counts = repeated_weaknesses_counts(findings).map do |c|
        { content: c.to_s, align: :center }
      end

      [
        I18n.t('review.repeated_weaknesses'),
        counts,
        {
          content: "<b>#{repeated_weaknesses_counts(findings).sum}</b>",
          align: :center
        }
      ].flatten
    end

    def total_weaknesses_row findings
      counts = total_weaknesses_counts(findings).map do |t|
        { content: "<b>#{t}</b>", align: :center }
      end

      [
        "<b>#{I18n.t('label.total')}</b>",
        counts,
        {
          content: "<b>#{total_weaknesses_counts(findings).sum}</b>",
          align: :center
        }
      ].flatten
    end

    def weaknesses_brief_column_widths pdf
      columns_count = self.class.risks.size + 2

      columns_count.times.map do
        pdf.percent_width 100.0 / columns_count
      end
    end

    def weaknesses_brief_column_headers
      [
        '',
        self.class.risks.to_a.reverse.map do |risk, value|
          { content: "<b>#{I18n.t "risk_types.#{risk}"}</b>", align: :center }
        end,
        { content: "<b>#{I18n.t('label.total')}</b>", align: :center }
      ].flatten
    end

    def new_weaknesses_counts findings
      self.class.risks.to_a.reverse.map do |risk, value|
        findings.not_revoked.where(risk: value, repeated_of_id: nil).count
      end
    end

    def repeated_weaknesses_counts findings
      self.class.risks.to_a.reverse.map do |risk, value|
        findings.not_revoked.where(risk: value).where.not(repeated_of_id: nil).count
      end
    end

    def total_weaknesses_counts findings
      new_counts      = new_weaknesses_counts findings
      repeated_counts = repeated_weaknesses_counts findings

      self.class.risks.to_a.each_with_index.map do |risk, index|
        new_counts[index] + repeated_counts[index]
      end
    end
end
