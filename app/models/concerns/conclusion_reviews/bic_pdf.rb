module ConclusionReviews::BicPdf
  extend ActiveSupport::Concern

  def bic_pdf _organization = nil, *_args
    { pdf: pdf_name,
      template: 'conclusion_reviews/bic_pdf/conclusion_review.html.erb',
      margin: {
        top:    0,
        bottom: 0,
        left:   0,
        right:  0
      },
      orientation: 'Landscape',
      layout: 'pdf.html',
      disposition: 'attachment',
      show_as_html: false }
  end

  def bic_exclude_regularized_findings weaknesses
    if exclude_regularized_findings
      weaknesses.where.not(state: Finding::STATUS[:implemented_audited])
    else
      weaknesses
    end
  end
end
