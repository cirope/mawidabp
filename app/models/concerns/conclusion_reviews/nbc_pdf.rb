module ConclusionReviews::NbcPdf
  extend ActiveSupport::Concern

  def nbc_pdf organization = nil, *args
    pdf = Prawn::Document.create_generic_pdf :portrait

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
        review.plan_item.business_unit.name
      ].join "\n"

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.text text_title, size: (PDF_FONT_SIZE * 2).round, align: :center, valign: :center, inline_format: true

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      responsibles = review.review_user_assignments.where(owner: true)&.map do |rua|
                      rua.user.full_name
                     end
      column_data  = [
        [I18n.t('conclusion_review.nbc.cover.issue_date'), I18n.l(issue_date, format: :long)  ],
        [I18n.t('conclusion_review.nbc.cover.to'), I18n.t('conclusion_review.nbc.cover.to_label')],
        [I18n.t('conclusion_review.nbc.cover.from'), I18n.t('conclusion_review.nbc.cover.from_label')],
        [I18n.t('conclusion_review.nbc.cover.cc'), responsibles.join("\n") ]
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

      pdf.move_down PDF_FONT_SIZE * 15
      put_nbc_grid pdf

      pdf.start_new_page
    end

    def put_nbc_grid pdf
      column_data = [
        [
          I18n.t('conclusion_review.nbc.cover.number_review'),
          review.identification,
          I18n.t('conclusion_review.nbc.cover.prepared_by'),
          I18n.t('conclusion_review.nbc.cover.internal_audit')
        ]
      ]

      w_c = pdf.bounds.width / 4

      pdf.table(column_data, cell_style: { size: (PDF_FONT_SIZE * 0.75).round, inline_format: true },
                column_widths: w_c)
    end

    def put_nbc_brief_on pdf
      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.add_title I18n.t('conclusion_review.nbc.weaknesses.title'), *title_options
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.subtitle'), inline_format: true

      pdf.move_down PDF_FONT_SIZE
      pdf.text review.description, align: :justify, inline_format: true

      pdf.start_new_page
    end

    def put_nbc_weaknesses_on pdf
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.main_observations'), inline_format: true

      weaknesses.each do |weakness|
        pdf.text "• #{weakness.description}" if weakness.being_implemented?
      end

      pdf.start_new_page
    end

    def put_nbc_scores_on pdf
      pdf.text I18n.t('conclusion_review.nbc.scores.cycle'), inline_format: true
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.nbc.scores.description')

      data = [nbc_header_scores]

      nbc_get_weaknesses_by_risk.each do |row, weaknesses|
        risk_text = weaknesses.first.risk_text

        row.unshift weaknesses.size

        weight = row.inject &:*

        data << [risk_text] + row + [weight]
      end

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
        pdf.text I18n.t('conclusion_review.nbc.scores.legend_score')
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
        { content: I18n.t('conclusion_review.nbc.scores.footer_table'), colspan: 5},
        I18n.t("conclusion_review.nbc.results_by_weighting.#{score.first}")
      ]
    end

    def nbc_get_weaknesses_by_risk
      weaknesses.select { |w| w.state_weight > 0 }.group_by do |w|
        [w.risk_weight, w.state_weight, w.age_weight(date: issue_date)]
      end
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
          if manager
            pdf.text I18n.t('conclusion_review.nbc.weaknesses.highest_responsible', responsible: manager.full_name), inline_format: true
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
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.introduction',
                      date: I18n.l(review.plan_item.end, format: :long),
                      project: review.plan_item.project)

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.scope')

      pdf.move_down PDF_FONT_SIZE
      pdf.text applied_procedures, align: :justify, inline_format: true

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.review_procedures')

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text I18n.t('conclusion_review.nbc.weaknesses.messages')

      data = review.review_user_assignments.select(&:include_signature).map do |rua|
               [rua.user.full_name, rua.user.full_name]
             end

      width_column1 = PDF_FONT_SIZE * 10
      width_column2 = pdf.bounds.width - width_column1

      pdf.move_down PDF_FONT_SIZE

      data.insert 0, [
        I18n.t('conclusion_review.nbc.weaknesses.full_name'),
        I18n.t('conclusion_review.nbc.weaknesses.area')
      ]

      pdf.table(data, cell_style: { inline_format: true }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          background_color: 'cccccc',
          align: :center
        )
      end
    end

    def put_nbc_weaknesses_detected_on pdf
      pdf.start_new_page

      pdf.text I18n.t('conclusion_review.nbc.weaknesses_detected.name')

      weaknesses.each do |weakness|
        pdf.move_down PDF_FONT_SIZE
        put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.title')

        pdf.move_down PDF_FONT_SIZE
        pdf.text weakness.title

        pdf.move_down PDF_FONT_SIZE
        put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.description')
        pdf.move_down PDF_FONT_SIZE
        pdf.text weakness.description

        pdf.move_down PDF_FONT_SIZE
        put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.effect')
        pdf.move_down PDF_FONT_SIZE
        pdf.text weakness.effect

        pdf.move_down PDF_FONT_SIZE
        put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.audit_recommendations')
        pdf.move_down PDF_FONT_SIZE
        pdf.text weakness.audit_recommendations

        pdf.move_down PDF_FONT_SIZE
        put_nbc_table_for_weakness_detected pdf, I18n.t('conclusion_review.nbc.weaknesses_detected.audit_comments')
        pdf.move_down PDF_FONT_SIZE
        pdf.text weakness.audit_comments

        pdf.move_down PDF_FONT_SIZE
        nbc_responsible_and_follow_up_date weakness, pdf
      end
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

      pdf.table(data, cell_style: { inline_format: true }, column_widths: [width_column1, width_column2]) do
        row(0).style(
          background_color: 'cccccc',
          align: :center
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
