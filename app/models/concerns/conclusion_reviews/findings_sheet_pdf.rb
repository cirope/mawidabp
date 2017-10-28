module ConclusionReviews::FindingsSheetPDF
  extend ActiveSupport::Concern

  def create_findings_sheet_pdf organization = nil, index = 1
    use_finals = kind_of? ConclusionFinalReview
    weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

    if weaknesses.any?
      pdf = Prawn::Document.create_generic_pdf :portrait, false

      pdf.add_watermark I18n.t('pdf.draft') if kind_of? ConclusionDraftReview

      pdf.add_review_header organization || self.organization,
        review&.identification,
        review&.plan_item&.project

      pdf.move_down (PDF_FONT_SIZE * 1.5).round
      put_weaknesses_sheet_on pdf, weaknesses
      pdf.custom_save_as findings_sheet_name(index), 'conclusion_reviews', id
    end
  end

  def absolute_findings_sheet_pdf_path index = 1
    Prawn::Document.absolute_path findings_sheet_name(index), 'conclusion_reviews', id
  end

  def relative_findings_sheet_pdf_path index = 1
    Prawn::Document.relative_path findings_sheet_name(index), 'conclusion_reviews', id
  end

  def findings_sheet_name index = 1
    I18n.t 'conclusion_review.findings_sheet.pdf_name', prefix: '%02d' % index
  end

  private

    def put_weaknesses_sheet_on pdf, weaknesses
      pdf.add_title I18n.t('conclusion_review.findings_sheet.title'),
        (PDF_FONT_SIZE * 1.5).round, :center

      pdf.move_down (PDF_FONT_SIZE * 1.5).round

      weaknesses.sort { |w1, w2| w1.review_code <=> w2.review_code }.each do |w|
        attributes = [w.review_code, w.title, w.risk_text, w.state_text]

        pdf.text attributes.join(' - '), font_size: PDF_FONT_SIZE

        w.work_papers.each do |wp|
          pdf.text "• #{wp.inspect}", indent_paragraphs: PDF_FONT_SIZE * 2
        end
      end
    end
end
