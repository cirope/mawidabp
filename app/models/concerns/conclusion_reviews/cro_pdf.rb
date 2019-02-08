module ConclusionReviews::CroPDF
  extend ActiveSupport::Concern

  def cro_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait

    put_default_watermark_on pdf
    put_cro_header_on        pdf, organization

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_cro_header_on pdf, organization
      pdf.add_review_header organization, nil, nil
      pdf.add_page_footer
    end
end
