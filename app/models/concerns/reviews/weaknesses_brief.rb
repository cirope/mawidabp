module Reviews::WeaknessesBrief
  extend ActiveSupport::Concern

  def put_weaknesses_brief_table pdf, finals, date
    column_data = weaknesses_brief_column_data finals, date

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

    def weaknesses_brief_column_data finals, date
      findings = finals ? final_weaknesses : weaknesses

      [
        new_weaknesses_row(findings, date),
        repeated_weaknesses_row(findings, date),
        total_weaknesses_row(findings, date)
      ]
    end

    def new_weaknesses_row findings, date
      counts = new_weaknesses_counts(findings, date).map do |c|
        { content: c.to_s, align: :center }
      end

      [
        I18n.t('review.new_weaknesses'),
        counts,
        {
          content: "<b>#{new_weaknesses_counts(findings, date).sum}</b>",
          align: :center
        }
      ].flatten
    end

    def repeated_weaknesses_row findings, date
      counts = repeated_weaknesses_counts(findings, date).map do |c|
        { content: c.to_s, align: :center }
      end

      [
        I18n.t('review.repeated_weaknesses'),
        counts,
        {
          content: "<b>#{repeated_weaknesses_counts(findings, date).sum}</b>",
          align: :center
        }
      ].flatten
    end

    def total_weaknesses_row findings, date
      counts = total_weaknesses_counts(findings, date).map do |t|
        { content: "<b>#{t}</b>", align: :center }
      end

      [
        "<b>#{I18n.t('label.total')}</b>",
        counts,
        {
          content: "<b>#{total_weaknesses_counts(findings, date).sum}</b>",
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

    def new_weaknesses_counts findings, date
      self.class.risks.to_a.reverse.map do |risk, value|
        count = 0

        findings.not_revoked.where(risk: value).each do |f|
          count += 1 unless f.take_as_repeated_for_score? date: date
        end

        count
      end
    end

    def repeated_weaknesses_counts findings, date
      self.class.risks.to_a.reverse.map do |risk, value|
        count = 0

        findings.not_revoked.where(risk: value).each do |f|
          count += 1 if f.take_as_repeated_for_score? date: date
        end

        count
      end
    end

    def total_weaknesses_counts findings, date
      new_counts      = new_weaknesses_counts findings, date
      repeated_counts = repeated_weaknesses_counts findings, date

      self.class.risks.to_a.each_with_index.map do |risk, index|
        new_counts[index] + repeated_counts[index]
      end
    end
end
