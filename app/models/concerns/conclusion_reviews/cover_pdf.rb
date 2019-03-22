module ConclusionReviews::CoverPDF
  extend ActiveSupport::Concern

  def create_cover_pdf organization = nil, text = nil, pdf_name = 'cover.pdf'
    pdf = Prawn::Document.create_generic_pdf :portrait, footer: false

    pdf.add_review_header organization || self.organization,
      review&.identification,
      review&.plan_item&.project

    pdf.move_down PDF_FONT_SIZE * 8

    pdf.add_title text, PDF_FONT_SIZE * 2, :center

    pdf.add_watermark I18n.t('pdf.draft') unless kind_of? ConclusionFinalReview

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  def absolute_cover_pdf_path pdf_name = 'cover.pdf'
    Prawn::Document.absolute_path pdf_name, ConclusionReview.table_name, id
  end

  def relative_cover_pdf_path pdf_name = 'cover.pdf'
    Prawn::Document.relative_path pdf_name, ConclusionReview.table_name, id
  end
end
