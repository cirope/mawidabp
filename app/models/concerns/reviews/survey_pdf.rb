module Reviews::SurveyPDF
  extend ActiveSupport::Concern

  def survey_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :portrait

    pdf.add_review_header organization, identification, plan_item.project

    add_survey_body_to pdf

    pdf.custom_save_as survey_pdf_name, 'review_surveys', id
  end

  def absolute_survey_pdf_path
    Prawn::Document.absolute_path survey_pdf_name, 'review_surveys', id
  end

  def relative_survey_pdf_path
    Prawn::Document.relative_path survey_pdf_name, 'review_surveys', id
  end

  def survey_pdf_name
    survey_label = Review.human_attribute_name('survey').downcase

    "#{survey_label}-#{identification}.pdf".sanitized_for_filename
  end

  private

    def add_survey_body_to pdf
      footnote_text = if file_model&.file?
                        I18n.t 'review.survey.with_attachment'
                      else
                        I18n.t 'review.survey.without_attachment'
                      end

      pdf.add_title Review.human_attribute_name('survey')
      pdf.move_down PDF_FONT_SIZE

      pdf.text survey, font_size: PDF_FONT_SIZE, align: :justify
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.add_footnote "<i>#{footnote_text}</i>"
    end
end
