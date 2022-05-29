module ConclusionReviews::Rtf
  extend ActiveSupport::Concern

  def to_rtf organization = nil, *args
    send "#{Current.conclusion_pdf_format}_rtf", organization, *args
  end

  def rtf_name
    identification = review.sanitized_identification[0..120]
    model_name     = ConclusionReview.model_name.human.downcase.gsub /\s/, '_'

    "#{model_name}-#{identification}"
  end
end
