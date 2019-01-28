module ConclusionReviews::BicPDF
  extend ActiveSupport::Concern

  def bic_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait

    put_default_watermark_on pdf
    put_bic_header_on        pdf, organization

    pdf.text 'Prueba'

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_bic_header_on pdf, organization
      pdf.add_review_header organization, nil, nil

      pdf.repeat :all do
        y_pointer = pdf.y

        pdf.canvas do
          coordinates = [
            pdf.page.margins[:left],
            pdf.bounds.top - PDF_FONT_SIZE.pt * 2
          ]

          pdf.text_box review.identification, at: coordinates, size: PDF_FONT_SIZE,
            width: pdf.bounds.width, align: :center
        end

        pdf.y = y_pointer
      end
    end
end
