module ConclusionReviews::FindingsFollowUpPDF
  extend ActiveSupport::Concern

  def create_findings_follow_up_pdf organization = nil, index = 1
    use_finals   = kind_of? ConclusionFinalReview
    weaknesses   = sorted_follow_up_findings :weaknesses, use_finals
    oportunities = sorted_follow_up_findings :oportunities, use_finals

    if weaknesses.any? || oportunities.any?
      pdf = Prawn::Document.create_generic_pdf :portrait, footer: false

      pdf.add_watermark I18n.t('pdf.draft') if kind_of? ConclusionDraftReview

      pdf.add_review_header organization || self.organization,
        review&.identification,
        review&.plan_item&.project

      pdf.move_down (PDF_FONT_SIZE * 1.5).round

      put_findings_follow_up_on pdf, weaknesses, oportunities

      pdf.custom_save_as findings_follow_up_name(index), ConclusionReview.table_name, id
    end
  end

  def absolute_findings_follow_up_pdf_path index = 1
    Prawn::Document.absolute_path findings_follow_up_name(index), 'conclusion_reviews', id
  end

  def relative_findings_follow_up_pdf_path index = 1
    Prawn::Document.relative_path findings_follow_up_name(index), 'conclusion_reviews', id
  end

  def findings_follow_up_name index = 1
    I18n.t 'conclusion_review.findings_follow_up.pdf_name', prefix: '%02d' % index
  end

  private

    def put_findings_follow_up_on pdf, weaknesses, oportunities
      title = I18n.t 'conclusion_review.findings_follow_up.title'

      pdf.add_title title, (PDF_FONT_SIZE * 1.5).round, :center

      put_finding_table_follow_up_on pdf, :weaknesses, weaknesses
      put_finding_table_follow_up_on pdf, :oportunities, oportunities

      put_finding_follow_up_on pdf, :weakness, weaknesses
      put_finding_follow_up_on pdf, :oportunity, oportunities
    end

    def put_finding_table_follow_up_on pdf, type, findings
      clarification = I18n.t 'conclusion_review.findings_follow_up.index_clarification'
      data          = []

      pdf.move_down PDF_FONT_SIZE * 2 if findings.any?

      findings.each do |finding|
        data << [
          finding.review_code,
          finding.title,
          (finding.risk_text if type == :weaknesses),
          finding.state_text
        ].compact
      end

      if data.present?
        table_data    = data.insert 0, follow_up_column_headers(type)
        table_options = pdf.default_table_options follow_up_column_widths(pdf, type)

        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          pdf.table table_data, table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end

        pdf.text "\n#{clarification}", font_size: (PDF_FONT_SIZE * 0.75).round,
          align: :justify
      end
    end

    def put_finding_follow_up_on pdf, type, findings
      findings.each do |finding|
        title      = I18n.t "conclusion_review.findings_follow_up.#{type}_title_in_singular"
        attributes = [
          finding.review_code,
          finding.title,
          (finding.risk_text if type == :weakness),
          finding.state_text
        ].compact

        pdf.start_new_page

        pdf.move_down (PDF_FONT_SIZE * 1.5).round
        pdf.add_title title, (PDF_FONT_SIZE * 1.5).round, :center
        pdf.move_down (PDF_FONT_SIZE * 1.5).round

        pdf.text attributes.join(' - '), font_size: PDF_FONT_SIZE, align: :center
      end
    end

    def sorted_follow_up_findings type, use_finals
      findings = use_finals ? review.send(:"final_#{type}") : review.send(type)

      findings = findings.select do |f|
        f.implemented? || f.being_implemented? || f.unanswered?
      end

      findings.sort do |f1, f2|
        f1.review_code <=> f2.review_code
      end
    end

    def follow_up_column_names
      [
        ['review_code', 20],
        ['title', 40],
        ['risk', 20],
        ['state', 20]
      ]
    end

    def follow_up_column_widths pdf, type
      widths = if type == :weaknesses
                 [20, 40, 20, 20]
               else
                 [20, 60, 20]
               end

      widths.map { |width| pdf.percent_width width }
    end

    def follow_up_column_headers type
      headers = if type == :weaknesses
                  ['review_code', 'title', 'risk', 'state']
                else
                  ['review_code', 'title', 'state']
                end

      headers.map do |header|
        sufix = ['risk', 'state'].include?(header) ? ' *' : ''

        Finding.human_attribute_name(header) + sufix
      end
    end
end
