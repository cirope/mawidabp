module ConclusionReviews::NbcPdf
  extend ActiveSupport::Concern

  def nbc_pdf organization = nil, *args
    pdf = Prawn::Document.create_generic_pdf :portrait

    put_nbc_cover_on               pdf, organization
    put_nbc_watermark_on           pdf
    put_nbc_brief_on               pdf
    put_nbc_weaknesses_on          pdf
    put_nbc_conclusion_on          pdf
    put_nbc_weaknesses_detailed_on pdf
    put_nbc_weaknesses_detected_on pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_nbc_cover_on pdf, organization
      pdf.add_review_header organization, nil, nil

      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false, :center]

      pdf.move_down PDF_FONT_SIZE

      width       = pdf.bounds.width
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]
      text_title  = [I18n.t('conclusion_review.detailed_review.title'),
                    review.plan_item.business_unit.name].join("\n")

      pdf.bounding_box(coordinates, width: width, height: 150) do
        pdf.add_title text_title, *title_options
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title '', *title_options

        pdf.stroke_bounds
      end

      pdf.move_down PDF_FONT_SIZE * 10

      review_owners = review.review_user_assignments.where owner: true
      responsibles  = []

      if review_owners.present?
        review_owners.map do |rua|
          responsibles.push(rua.user.full_name)
        end
      end

      column_data = [
        [I18n.t('conclusion_review.detailed_review.to'), I18n.t('conclusion_review.detailed_review.to_label')],
        [I18n.t('conclusion_review.detailed_review.from'), I18n.t('conclusion_review.detailed_review.from_label')],
        [I18n.t('conclusion_review.detailed_review.cc'), responsibles.join("\n") ]
      ]

      pdf.font_size(((PDF_FONT_SIZE).round).pt)

      width_column1 = pdf.bounds.width - PDF_FONT_SIZE * 35
      width_column2 = pdf.bounds.width - width_column1

      pdf.table(column_data, column_widths: [width_column1, width_column2]) do
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
          I18n.t('conclusion_review.detailed_review.number_review'),
          review.identification,
          I18n.t('conclusion_review.detailed_review.prepared_by'),
          I18n.t('conclusion_review.detailed_review.internal_audit')
        ],
        [
          I18n.t('conclusion_review.detailed_review.audit_date'),
          I18n.l(issue_date, format: :specific),'',''
        ]
      ]

      pdf.font_size(((PDF_FONT_SIZE * 0.75).round).pt)

      w_c = pdf.bounds.width / 4

      pdf.table(column_data, :column_widths => [w_c,w_c,w_c,w_c,]) do
        row(0).style(
          :borders =>[:top, :left, :right]
        )
        row(1).style(
          :borders =>[:bottom, :left, :right]
        )
      end
    end

    def put_nbc_brief_on pdf
      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.add_title I18n.t('conclusion_review.executive_summary.title'), *title_options
      pdf.add_subtitle I18n.t('conclusion_review.executive_summary.subtitle')

      pdf.text review.description, align: :justify, inline_format: true

      pdf.start_new_page
    end

    def put_nbc_weaknesses_on pdf
      pdf.add_title I18n.t('conclusion_review.detailed_review.main_observations')

      review.weaknesses.each do |weakness|
        pdf.text weakness.description if weakness.implemented_status
      end
    end

    def put_nbc_conclusion_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.add_subtitle I18n.t('conclusion_review.detailed_review.audit_conclusion')

      if conclusion.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text conclusion, align: :justify, inline_format: true

        pdf.move_down PDF_FONT_SIZE * 5

        pdf.font_size (PDF_FONT_SIZE).round do
          pdf.text "<b>Cr Favio Benzaquen</b>", inline_format: true
          pdf.text I18n.t('conclusion_review.detailed_review.signature_label'), inline_format: true
          pdf.text I18n.t('conclusion_review.detailed_review.organization'), inline_format: true
        end
      end

      pdf.start_new_page
    end

    def put_nbc_weaknesses_detailed_on pdf
      title_options     = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.add_title I18n.t('conclusion_review.detailed_review.detailed_review'), *title_options

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.add_subtitle I18n.t('conclusion_review.detailed_review.introduction_and_scope')

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_review.detailed_review.introduction',
                      date: I18n.l(review.plan_item.end, format: :long),
                      project: review.plan_item.project)

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.add_subtitle I18n.t('conclusion_review.detailed_review.scope')

      pdf.move_down PDF_FONT_SIZE

      review.grouped_control_objective_items.each do |process_control, cois|
        coi_data              = cois.sort.map { |coi| ['• ', coi.to_s] }
        process_control_text = "<i>#{process_control.name}</i></b>"

        pdf.text process_control_text, align: :justify, inline_format: true
      end

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_review.detailed_review.review_procedures')

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text 'Nuestro trabajo se realizó en los meses de noviembre y diciembre de 2020, y para llevarlo a cabo se mantuvieron reuniones con el siguiente personal de Entidad:
      '
      data  = []
      users = review.review_user_assignments.select(&:include_signature)

      users = users.sort_by do  |rua|
        data.push([rua.user.full_name, rua.user.full_name])
      end

      width_column1 = pdf.bounds.width - PDF_FONT_SIZE * 30
      width_column2 = pdf.bounds.width - width_column1

      pdf.move_down PDF_FONT_SIZE

      data.insert 0, [
        I18n.t('conclusion_review.detailed_review.full_name'),
        I18n.t('conclusion_review.detailed_review.area')
      ]

      pdf.table(data, :column_widths => [width_column1, width_column2]) do
        row(0).style(
          background_color: 'cccccc',
        )
      end

      pdf.start_new_page
    end

    def put_nbc_weaknesses_detected_on pdf
      pdf.add_subtitle I18n.t('conclusion_review.weaknesses_detected.name')

      review.weaknesses.each do |weakness|
        pdf.move_down PDF_FONT_SIZE

        pdf.text I18n.t('conclusion_review.weaknesses_detected.title'), inline_format: true

        pdf.text weakness.review_code

        pdf.move_down PDF_FONT_SIZE

        pdf.text I18n.t('conclusion_review.weaknesses_detected.description'), inline_format: true

        pdf.text weakness.description

        pdf.move_down PDF_FONT_SIZE

        pdf.text I18n.t('conclusion_review.weaknesses_detected.effect'), inline_format: true

        pdf.text weakness.effect

        pdf.move_down PDF_FONT_SIZE

        pdf.text I18n.t('conclusion_review.weaknesses_detected.audit_recommendations'), inline_format: true

        pdf.text weakness.audit_recommendations

        pdf.move_down PDF_FONT_SIZE

        pdf.text I18n.t('conclusion_review.weaknesses_detected.audit_comments'), inline_format: true

        pdf.text weakness.audit_comments

        pdf.move_down PDF_FONT_SIZE

        data = [
          [ nbc_weakness_responsible(weakness),
            (weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-')
          ]
        ]

        data.insert 0, [
          I18n.t('conclusion_review.detailed_review.responsible_name'),
          I18n.t('conclusion_review.detailed_review.follow_up_date')
        ]

        width_column1 = pdf.bounds.width - PDF_FONT_SIZE * 30
        width_column2 = pdf.bounds.width - width_column1

        pdf.table(data, :column_widths => [width_column1, width_column2]) do
          row(0).style(
            background_color: 'cccccc',
          )
        end
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

    def put_nbc_watermark_on pdf
      if instance_of? ConclusionDraftReview
        pdf.add_watermark ConclusionDraftReview.model_name.human
      end
    end
end
