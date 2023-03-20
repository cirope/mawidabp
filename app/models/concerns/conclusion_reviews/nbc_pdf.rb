module ConclusionReviews::NbcPdf
  extend ActiveSupport::Concern

  def nbc_pdf organization = nil, *args
    pdf = Prawn::Document.create_generic_pdf :portrait, margins: [30, 20, 20, 25]

    put_nbc_cover_on               pdf, organization
    put_default_watermark_on       pdf
    put_nbc_brief_on               pdf
    put_nbc_weaknesses_on          pdf
    put_nbc_scores_on              pdf
    put_nbc_conclusion_on          pdf
    put_nbc_weaknesses_detailed_on pdf
    put_nbc_weaknesses_detected_on pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_nbc_cover_on pdf, organization
      pdf.add_review_header organization, nil, nil

      pdf.move_down PDF_FONT_SIZE

      width       = pdf.bounds.width
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]
      text_title  = [
        I18n.t('conclusion_review.nbc.cover.title'),
        review.description
      ].join "\n"

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.text text_title, size: (PDF_FONT_SIZE * 1.5).round, align: :center, valign: :center, inline_format: true

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      if recipients.present?
        responsibles = recipients.lines.reject(&:blank?).map do |recipient|
          "• #{recipient}"
        end
      end

      column_data  = [
        [I18n.t('conclusion_review.nbc.cover.issue_date'), I18n.l(issue_date, format: :long)  ],
        [I18n.t('conclusion_review.nbc.cover.to'), I18n.t('conclusion_review.nbc.cover.to_label')],
        [I18n.t('conclusion_review.nbc.cover.from'), I18n.t('conclusion_review.nbc.cover.from_label')],
        [I18n.t('conclusion_review.nbc.cover.cc'), responsibles&.join("\n") ]
      ]

      width_column1 = PDF_FONT_SIZE * 7
      width_column2 = pdf.bounds.width - width_column1

      pdf.table(column_data, cell_style: { inline_format: true }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          borders: [:top, :left, :right]
        )
        row(1).style(
          borders: [:left, :right]
        )
        row(2).style(
          borders: [:bottom, :left, :right]
        )
      end

      pdf.move_down (pdf.y - PDF_FONT_SIZE.pt * 8)
      put_nbc_grid pdf

      pdf.start_new_page
    end

    def put_nbc_grid pdf
      column_data = [
        [
          "#{I18n.t('conclusion_review.nbc.cover.number_review')}: #{review.identification}",
          I18n.t('conclusion_review.nbc.cover.prepared_by')
        ]
      ]

      w_c = pdf.bounds.width / 2

      pdf.table(column_data, cell_style: { size: (PDF_FONT_SIZE * 0.75).round, inline_format: true },
                column_widths: w_c)
    end

    def put_nbc_brief_on pdf
      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.add_title I18n.t('conclusion_review.nbc.weaknesses.title'), *title_options

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.subtitle'), inline_format: true

      pdf.move_down PDF_FONT_SIZE
      pdf.text review.review_objective, align: :justify, inline_format: true
    end

    def put_nbc_weaknesses_on pdf
      bi_weaknesses, ia_weaknesses = review.ia_or_bi_weaknesses.partition(&:being_implemented?)

      bi_alt_weaknesses = []
      ia_alt_weaknesses = []

      review.external_reviews.map(&:alternative_review).map do |ar|
        alt_weaknesses = ar.ia_or_bi_weaknesses

        if alt_weaknesses.any?(&:being_implemented?)
          bi_alt_weaknesses << [ar.identification, alt_weaknesses.select(&:being_implemented?)]
        end

        if alt_weaknesses.any?(&:implemented_audited?)
          ia_alt_weaknesses << [ar.identification, alt_weaknesses.select(&:implemented_audited?)]
        end
      end

      if bi_weaknesses.any? || bi_alt_weaknesses.any?
        main_weaknesses_partial pdf, bi_weaknesses, bi_alt_weaknesses, 'being_implemented'
      end

      if ia_weaknesses.any? || ia_alt_weaknesses.any?
        main_weaknesses_partial pdf, ia_weaknesses, ia_alt_weaknesses, 'implemented_audited'
      end

      pdf.start_new_page
    end

    def main_weaknesses_partial pdf, weaknesses, alt_weaknesses, status
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t("conclusion_review.nbc.weaknesses.main_#{status}"), inline_format: true
      pdf.move_down PDF_FONT_SIZE

      if weaknesses.any?
        weaknesses.each do |weakness|
          pdf.text "• #{weakness.title}"
        end

        pdf.move_down PDF_FONT_SIZE
      end

      if alt_weaknesses.any?
        alt_weaknesses.each do |review_name, alt_w|
          pdf.text "#{I18n.t('conclusion_review.nbc.weaknesses.from_external_review')} #{review_name}:", style: :italic
          pdf.move_down PDF_FONT_SIZE

          alt_w.each do |alt_weakness|
            pdf.text "• #{alt_weakness.title}"
          end

          pdf.move_down PDF_FONT_SIZE
        end
      end
    end

    def put_nbc_scores_on pdf
      if review[:type_review] == Review::TYPES_REVIEW[:operational_audit]
        pdf.text I18n.t('conclusion_review.nbc.scores.cycle'), inline_format: true
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.nbc.scores.description'), align: :justify

        data       = [nbc_header_scores]
        sum_weight = 0
        total_sum  = 0

        review.score_by_weakness_reviews(issue_date).each do |row, weaknesses|
          risk_text = weaknesses.first.risk_text

          row.unshift weaknesses.size

          weight      = row.inject &:*
          sum_weight += weight
          total_sum  += weaknesses.count

          data << [risk_text] + row + [weight]
        end

        data << [I18n.t('conclusion_review.nbc.scores.total'), total_sum, '', '', '', sum_weight]
        data << nbc_footer_scores(review.score_array)

        pdf.move_down PDF_FONT_SIZE

        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          pdf.table data do |t|
            t.cells.align = :center
            t.cells.row(0).style(
              background_color: '6e9fcf',
              align: :center,
              font_style: :bold
            )
            t.cells.row(-1).style(
              background_color: '6e9fcf',
              align: :center,
              font_style: :bold
            )
          end

          pdf.move_down PDF_FONT_SIZE
          pdf.text I18n.t('conclusion_review.nbc.scores.legend_score'), align: :justify
        end
      end
    end

    def nbc_header_scores
      [
        I18n.t('conclusion_review.nbc.scores.risk'),
        I18n.t('conclusion_review.nbc.scores.amount_weaknesses'),
        I18n.t('conclusion_review.nbc.scores.level_risk'),
        I18n.t('conclusion_review.nbc.scores.status'),
        I18n.t('conclusion_review.nbc.scores.age_parameter'),
        I18n.t('conclusion_review.nbc.scores.weighing')
      ]
    end

    def nbc_footer_scores score
      [
        { content: I18n.t('conclusion_review.nbc.scores.footer_table'), colspan: 5 },
        I18n.t("conclusion_review.nbc.results_by_weighting.#{score.first}")
      ]
    end

    def put_nbc_conclusion_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.audit_conclusion'), inline_format: true

      if conclusion.present?
        manager = User.list.managers.not_hidden.take

        pdf.move_down PDF_FONT_SIZE
        pdf.text conclusion, align: :justify, inline_format: true

        pdf.move_down PDF_FONT_SIZE * 5

        pdf.font_size (PDF_FONT_SIZE).round do

          responsible = review.review_user_assignments.detect do |rua|
            rua.responsible?
          end

          if responsible.present?
            pdf.text I18n.t('conclusion_review.nbc.weaknesses.highest_responsible', responsible: responsible.user.full_name), inline_format: true
            pdf.text I18n.t('conclusion_review.nbc.weaknesses.signature_label'), inline_format: true
            pdf.text I18n.t('conclusion_review.nbc.weaknesses.organization'), inline_format: true
          end
        end
      end

      pdf.start_new_page
    end

    def put_nbc_weaknesses_detailed_on pdf
      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.add_title I18n.t('conclusion_review.nbc.weaknesses.detailed_review'), *title_options

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.introduction_and_scope'), inline_format: true

      pdf.move_down PDF_FONT_SIZE
      pdf.text applied_procedures, align: :justify, inline_format: true

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.messages'), align: :justify

      pdf.move_down PDF_FONT_SIZE

      data = review.review_user_assignments.select(&:audited?).map { |rua| [rua.user.full_name] }

      data.insert 0, [I18n.t('conclusion_review.nbc.weaknesses.full_name')]
      pdf.table(data, cell_style: { inline_format: true }, column_widths: [pdf.bounds.width]) do
        row(0).style(
          background_color: 'cccccc',
          align: :center
        )
      end
    end

    def put_nbc_weaknesses_detected_on pdf
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

      repeated      = weaknesses.not_revoked.where.not repeated_of_id: nil
      title_options = [(PDF_FONT_SIZE).round, :center, false]

      finding_assignments = review.finding_review_assignments.map(&:finding).select do |fra|
        fra.state == Finding::STATUS[:implemented_audited]
      end

      if repeated.any? || finding_assignments.any?
        pdf.start_new_page
        pdf.add_title I18n.t('conclusion_review.nbc.weaknesses_detected.repeated'), *title_options

        repeated_findings = repeated + finding_assignments

        repeated_findings.each_with_index do |weakness, idx|
          weakness_partial pdf, weakness

          pdf.start_new_page if idx < repeated_findings.size - 1
        end
      end

      if weaknesses.not_revoked.where(repeated_of_id: nil).any?
        pdf.start_new_page
        pdf.add_title I18n.t('conclusion_review.nbc.weaknesses_detected.name'), *title_options
      end

      findings = weaknesses.not_revoked.where(repeated_of_id: nil)

      findings.each_with_index do |weakness, idx|
        weakness_partial pdf, weakness

        pdf.start_new_page if idx < findings.size - 1
      end
    end

    def weakness_partial pdf, weakness
      pdf.move_down PDF_FONT_SIZE
      put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.title')
      pdf.move_down PDF_FONT_SIZE
      pdf.text weakness.title

      pdf.move_down PDF_FONT_SIZE
      put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.description')
      pdf.move_down PDF_FONT_SIZE
      pdf.text weakness.description, align: :justify

      pdf.move_down PDF_FONT_SIZE
      nbc_risk_date_origination_header weakness, pdf

      pdf.move_down PDF_FONT_SIZE
      put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.audit_recommendations')
      pdf.move_down PDF_FONT_SIZE
      pdf.text weakness.audit_recommendations, align: :justify

      pdf.move_down PDF_FONT_SIZE
      put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.audit_comments')
      pdf.move_down PDF_FONT_SIZE
      pdf.text nbc_audit_answer_last(weakness.answer), align: :justify

      pdf.move_down PDF_FONT_SIZE
      nbc_responsible_and_follow_up_date weakness, pdf
    end

    def nbc_risk_date_origination_header weakness, pdf
      data = [
        [
          I18n.t('conclusion_review.nbc.weaknesses_detected.risk'),
          I18n.t('conclusion_review.nbc.weaknesses_detected.state'),
          I18n.t('conclusion_review.nbc.weaknesses_detected.origination_date')
        ],
        [
          weakness.risk_text,
          weakness.state_text,
          weakness.origination_date
        ]
      ]

      width_column1 = PDF_FONT_SIZE * 17
      width_column2 = (pdf.bounds.width - width_column1) / 2

      pdf.table(data, cell_style: { inline_format: true, border_width: 0 }, column_widths: [width_column1, width_column2, width_column2]) do
        row(0).style(
          background_color: 'EEEEEE'
        )
      end
    end

    def nbc_audit_answer_last answer
      answer.split("\r\n\r\n").last
    end

    def nbc_responsible_and_follow_up_date weakness, pdf
      data = [
        [
          nbc_weakness_responsible(weakness),
          (weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-')
        ]
      ]

      data.insert 0, [
        I18n.t('conclusion_review.nbc.weaknesses.responsible_name'),
        I18n.t('conclusion_review.nbc.weaknesses.follow_up_date')
      ]

      width_column1 = PDF_FONT_SIZE * 30
      width_column2 = pdf.bounds.width - width_column1

      pdf.table(data, cell_style: { inline_format: true, border_width: 0 }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          background_color: 'EEEEEE'
        )
      end
    end

    def nbc_weakness_responsible weakness
      assignments = weakness.finding_user_assignments.select do |fua|
        fua.user.can_act_as_audited?
      end

      if assignments.select(&:process_owner).any?
        assignments = assignments.select &:process_owner
      end

      assignments.map(&:user).map do |u|
        u.full_name_with_function issue_date
      end.join '; '
    end

    def put_nbc_table_for_weakness_detected pdf, value
      data = [[value]]

      w_c = pdf.bounds.width

      pdf.table(data, cell_style: { inline_format: true }, :column_widths => w_c) do
        row(0).style(
          background_color: 'EEEEEE',
          borders: [],
          padding: [
            (PDF_FONT_SIZE * 0.5).round,
            (PDF_FONT_SIZE * 0.3).round
          ]
        )
      end
    end
end
