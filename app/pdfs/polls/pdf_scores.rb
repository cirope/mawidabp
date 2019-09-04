module Polls::PdfScores
  extend ActiveSupport::Concern

  def pdf_add_scores
    pdf.move_down PDF_FONT_SIZE * 1.5
    pdf.text "#{I18n.t('polls.total_answered')}: #{@report.answered}"
    pdf.text "#{I18n.t('polls.total_unanswered')}: #{@report.unanswered}"
    pdf.move_down PDF_FONT_SIZE * 0.5
    pdf.text "#{I18n.t('polls.score')}: #{@report.calification}%"
  end
end
