module ConclusionReviews::BicPdf
  extend ActiveSupport::Concern

  def bic_pdf _organization, *_args
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string('conclusion_reviews/bic_pdf/conclusion_review.html.erb',
                       locals: { conclusion_review: self, draft: draft? }),
      header: {
        content: render_to_string('conclusion_reviews/bic_pdf/header.html.erb')
      },
      footer: {
        content: render_to_string('conclusion_reviews/bic_pdf/footer.html.erb')
      },
      pdf: pdf_name,
      margin: {
        top:    20,
        bottom: 5,
        left:   0,
        right:  0
      },
      orientation: 'Landscape'
    )

    pdf_path = absolute_pdf_path

    FileUtils.mkdir_p File.dirname(pdf_path)

    File.open(pdf_path, 'wb') { |file| file << pdf }
  end

  def bic_exclude_regularized_findings weaknesses
    if exclude_regularized_findings
      weaknesses.where.not(state: Finding::STATUS[:implemented_audited])
    else
      weaknesses
    end
  end

  private

    def render_to_string template, locals: {}, layout: 'pdf.html'
      ApplicationController.new.render_to_string template, locals: locals, layout: layout
    end
end
