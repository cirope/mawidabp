module ConclusionReviews::BicPdf
  extend ActiveSupport::Concern

  def bic_pdf _organization = nil, *_args
    { pdf: pdf_name,
      template: 'conclusion_reviews/bic_pdf/conclusion_review.html.erb',
      margin: {
        top:    19,
        bottom: 5,
        left:   0,
        right:  0
      },
      header: {
        html: {
          template: 'conclusion_reviews/bic_pdf/header.html.erb'
        }
      },
      footer: {
        html: {
          template: 'conclusion_reviews/bic_pdf/footer.html.erb'
        }
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
