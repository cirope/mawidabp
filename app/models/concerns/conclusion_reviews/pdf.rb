module ConclusionReviews::Pdf
  extend ActiveSupport::Concern

  def to_pdf organization = nil, *args
    send "#{Current.conclusion_pdf_format}_pdf", organization, *args
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, ConclusionReview.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, ConclusionReview.table_name, id
  end

  def pdf_name
    identification = review.sanitized_identification[0..120]
    model_name     = ConclusionReview.model_name.human.downcase.gsub /\s/, '_'

    "#{model_name}-#{identification}.pdf"
  end
end
