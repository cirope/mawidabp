module Polls::PDFHeaders
  extend ActiveSupport::Concern

  def pdf_add_header
    pdf.add_generic_report_header @current_organization
    pdf.add_title @report.params[:report_title], PDF_FONT_SIZE, :center
    pdf.move_down PDF_FONT_SIZE
    pdf.add_title @report.params[:report_subtitle], PDF_FONT_SIZE, :center
    pdf.move_down PDF_FONT_SIZE * 2
  end

  def pdf_add_description
    pdf.add_description_item(
      I18n.t('activerecord.attributes.poll.send_date'),
      I18n.t('conclusion_committee_report.period.range',
        from_date: I18n.l(@report.from_date, format: :long),
        to_date: I18n.l(@report.to_date, format: :long)
      )
    )
    pdf.move_down PDF_FONT_SIZE
    pdf.add_description_item(Questionnaire.model_name.human, @report.questionnaire.name)
    pdf.move_down PDF_FONT_SIZE * 2
  end

  def pdf_name
    I18n.t 'polls.pdf.name',
      from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)
  end

  def pdf
    @pdf
  end
end
