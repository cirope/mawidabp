module ConclusionReviews::BundleIndexPDF
  extend ActiveSupport::Concern

  def bundle_index_pdf organization = nil, index_items = nil
    pdf        = Prawn::Document.create_generic_pdf :portrait, false
    use_finals = kind_of? ConclusionFinalReview

    pdf.add_review_header organization || self.organization,
      review&.identification,
      review&.plan_item&.project

    pdf.add_watermark I18n.t('pdf.draft') unless use_finals

    pdf.move_down (PDF_FONT_SIZE * 1.5).round

    pdf.add_title I18n.t('conclusion_review.bundle_index.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    pdf.move_down (PDF_FONT_SIZE * 1.5).round

    put_index_items_on pdf, index_items

    pdf.custom_save_as bundle_index_pdf_name, ConclusionReview.table_name, id
  end

  def absolute_bundle_index_pdf_path
    Prawn::Document.absolute_path bundle_index_pdf_name,
      ConclusionReview.table_name, id
  end

  def relative_bundle_index_pdf_path
    Prawn::Document.relative_path bundle_index_pdf_name,
      ConclusionReview.table_name, id
  end

  def bundle_index_pdf_name
    I18n.t 'conclusion_review.bundle_index.pdf_name'
  end

  private

    def put_index_items_on pdf, index_items
      items_count = 1

      String(index_items).each_line do |line|
        if line.present?
          title = "#{'%02d' % items_count}. #{line.strip}"

          pdf.text title, font_size: (PDF_FONT_SIZE * 1.25).round

          items_count += 1
        end
      end
    end
end
