module ConclusionReviews::CroPDF
  extend ActiveSupport::Concern

  def cro_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait,
      hide_brand: true,
      margins:    [35, 20, 20, 25]

    put_default_watermark_on pdf
    put_cro_header_on        pdf, organization
    put_cro_cover_on         pdf, organization

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_cro_header_on pdf, organization
      put_first_page_header  pdf, organization
      put_other_pages_header pdf, organization

      pdf.add_page_footer
    end

    def put_cro_cover_on pdf, organization
      date = I18n.l(issue_date, format: :long).strip
      name = organization.name.upcase

      pdf.text I18n.t('conclusion_review.cro.cover.date', date: date),
        align: :right

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_review.cro.cover.to', organization: name),
        inline_format: true

      pdf.move_down PDF_FONT_SIZE * 4

      pdf.text I18n.t(
        'conclusion_review.cro.cover.reference',
        business_unit: review.business_unit.name.upcase,
        business_unit_type: review.business_unit_type.name.upcase
      ), align: :right, style: :bold

      pdf.move_down PDF_FONT_SIZE * 4

      pdf.text I18n.t('conclusion_review.cro.cover.text'), align: :justify

      put_cro_sign_on pdf
    end

    def put_cro_sign_on pdf
      width       = pdf.bounds.width / 2.5
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE * 8]

      pdf.bounding_box coordinates, width: width do
        pdf.put_hr
        pdf.text I18n.t('conclusion_review.cro.cover.sign'), align: :center,
          style: :bold
      end
    end

    def put_first_page_header pdf, organization
      y_pointer = pdf.y
      font_size = PDF_HEADER_FONT_SIZE

      pdf.add_organization_image organization, font_size * 2.25

      pdf.canvas do
        label       = I18n.t 'conclusion_review.cro.header.legend'
        coordinates = [
          pdf.bounds.width / 2.0,
          pdf.bounds.top - font_size.pt * 1.5
        ]

        pdf.text_box label, at: coordinates, size: font_size * 0.65,
          align: :right, inline_format: true,
          width: (coordinates[0] - pdf.page.margins[:right])
      end

      pdf.bounding_box [0, y_pointer - PDF_HEADER_FONT_SIZE * 3], width: pdf.bounds.width do
        pdf.put_hr
      end

      pdf.y = y_pointer
    end

    def put_other_pages_header pdf, organization
      y_pointer = pdf.y

      pdf.repeat ->(page) { page > 1 } do
        pdf.add_organization_image organization, PDF_HEADER_FONT_SIZE * 2.25
        pdf.add_organization_co_brand_image organization, PDF_HEADER_FONT_SIZE * 2.25

        pdf.bounding_box [0, y_pointer - PDF_HEADER_FONT_SIZE], width: pdf.bounds.width do
          pdf.put_hr
        end
      end

      pdf.y = y_pointer
    end
end
