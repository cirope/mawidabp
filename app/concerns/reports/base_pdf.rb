module Reports::BasePdf

  def init_pdf title, subtitle, options: {}
    pdf = Prawn::Document.create_generic_pdf :landscape, **options

    pdf.add_generic_report_header Current.organization

    pdf.add_title title, PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    if subtitle
      pdf.add_title subtitle, PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE * 2
    end

    pdf
  end

  def add_period_title pdf, period, align = :left
    pdf.move_down PDF_FONT_SIZE

    pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
      (PDF_FONT_SIZE * 1.25).round, align
  end

  def add_month_title pdf, month, align = :left
    pdf.move_down PDF_FONT_SIZE

    pdf.add_title I18n.l(month, format: '%B %Y'), (PDF_FONT_SIZE * 1.5).round, align
  end

  def add_pdf_filters pdf, controller, filters
    text = I18n.t(
      "#{controller}_committee_report.applied_filters",
      filters: filters.to_sentence, count: filters.size
    )

    pdf.move_down PDF_FONT_SIZE
    pdf.text text,
      font_size: (PDF_FONT_SIZE * 0.75).round, align: :justify,
      inline_format: true
  end
end
