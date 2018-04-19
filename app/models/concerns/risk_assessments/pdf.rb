module RiskAssessments::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header organization
    pdf.add_title *pdf_title

    pdf.custom_save_as pdf_name, RiskAssessment.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, RiskAssessment.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, RiskAssessment.table_name, id
  end

  def pdf_name
    I18n.t 'risk_assessments.pdf.pdf_name',
      name: name.sanitized_for_filename.downcase
  end

  private

    def pdf_title
      ["#{I18n.t('risk_assessments.pdf.title')}\n", (PDF_FONT_SIZE * 1.5).round, :center]
    end
end
