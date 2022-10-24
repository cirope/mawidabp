module ConclusionReviews::BicPdf
  extend ActiveSupport::Concern

  def bic_pdf organization = nil, *args
    pdf                = Prawn::Document.create_generic_pdf :portrait
    sort_by_risk_start = CONCLUSION_REVIEW_SORT_BY_RISK_START
    weaknesses         = if kind_of? ConclusionFinalReview
                           review.final_weaknesses
                         else
                           review.weaknesses
                         end

    weaknesses         = bic_exclude_regularized_findings weaknesses

    put_default_watermark_on pdf
    put_bic_header_on        pdf, organization
    put_bic_cover_on         pdf
    put_bic_review_on        pdf

    if sort_by_risk_start && created_at >= sort_by_risk_start
      put_bic_weaknesses_by_risk_and_repetition_on pdf if weaknesses.not_revoked.any?
      put_bic_images_by_risk_and_repetition_on     pdf if weaknesses.not_revoked.any? &:image_model
    else
      put_bic_weaknesses_on pdf if weaknesses.not_revoked.any?
      put_bic_images_on     pdf if weaknesses.not_revoked.any? &:image_model
    end

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def bic_exclude_regularized_findings weaknesses
      if exclude_regularized_findings
        weaknesses.where.not(state: Finding::STATUS[:implemented_audited])
      else
        weaknesses
      end
    end

    def put_bic_header_on pdf, organization
      font_size = PDF_HEADER_FONT_SIZE
      width     = pdf.bounds.width

      pdf.repeat :all do
        pdf.add_organization_image organization, font_size, factor: 0.9
        pdf.add_organization_co_brand_image organization, factor: 1

        pdf.canvas do
          put_bic_header_text_on pdf, organization, width
        end
      end
    end

    def put_bic_header_text_on pdf, organization, width
      logo_geometry    = organization.image_model&.image_geometry :pdf_thumb
      co_logo_geometry = organization.co_brand_image_model&.image_geometry :pdf_thumb
      max_logo_width   = [
        Hash(logo_geometry)[:width].to_i,
        Hash(co_logo_geometry)[:width].to_i
      ].max

      text_width  = width - max_logo_width - PDF_FONT_SIZE
      coordinates = [
        max_logo_width + PDF_FONT_SIZE / 2.0,
        pdf.bounds.top - PDF_FONT_SIZE.pt * 2
      ]

      text = I18n.t(
        'conclusion_review.bic.header', identification: review.identification
      )

      pdf.text_box text, at: coordinates, size: PDF_FONT_SIZE, align: :center,
        width: text_width
    end

    def put_bic_cover_on pdf
      pdf.font_size PDF_FONT_SIZE do
        table_options = pdf.default_table_options bic_cover_column_widths(pdf)

        pdf.table bic_cover_data, table_options.merge(row_colors: %w(ffffff))
      end

      put_bic_cover_note_on       pdf
      put_bic_cover_legend_on     pdf
      put_bic_cover_recipients_on pdf

      if kind_of?(ConclusionDraftReview) && review.weaknesses.any?
        pdf.move_down pdf.cursor - PDF_FONT_SIZE * 4
        pdf.put_hr
        pdf.text I18n.t('conclusion_review.bic.cover.footer'),
          size: PDF_FONT_SIZE * 0.6, align: :justify
      end
    end

    def put_bic_cover_note_on pdf
      note = if kind_of?(ConclusionDraftReview) && review.weaknesses.any?
               'draft_with_weaknesses'
             elsif kind_of?(ConclusionFinalReview) && review.weaknesses.any?
               'final_with_weaknesses'
             elsif kind_of? ConclusionFinalReview
               'final_without_weaknesses'
             end

      if note
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t("conclusion_review.bic.cover.#{note}"), align: :justify,
          size: PDF_FONT_SIZE, inline_format: true
      end
    end

    def put_bic_cover_legend_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.bic.cover.legend'),
        size: PDF_FONT_SIZE, align: :justify
      pdf.move_down PDF_FONT_SIZE * 5
    end

    def put_bic_cover_recipients_on pdf
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.text self.class.human_attribute_name('recipients').upcase,
        style: :bold

      pdf.move_down PDF_FONT_SIZE
      pdf.text recipients, align: :justify, inline_format: true
    end

    def put_bic_review_on pdf
      pdf.start_new_page

      put_bic_page_header_on      pdf, Review.model_name.human.upcase
      put_bic_review_data_on      pdf
      put_bic_review_text_data_on pdf
      put_bic_review_score_on     pdf
    end

    def put_bic_weaknesses_on pdf
      number      = 0
      header_text = I18n.t 'conclusion_review.bic.weaknesses.title'

      pdf.start_new_page

      put_bic_page_header_on pdf, header_text

      review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          weaknesses = if kind_of? ConclusionFinalReview
                         coi.final_weaknesses
                       else
                         coi.weaknesses
                       end

          weaknesses = bic_exclude_regularized_findings weaknesses

          weaknesses.not_revoked.sort_for_review.each do |weakness|
            put_bic_weakness_on pdf, weakness, number += 1
          end
        end
      end
    end

    def put_bic_weaknesses_by_risk_and_repetition_on pdf
      number     = 0
      weaknesses = if kind_of? ConclusionFinalReview
                     review.final_weaknesses
                   else
                     review.weaknesses
                   end

      weaknesses = bic_exclude_regularized_findings weaknesses
      present    = weaknesses.not_revoked.where repeated_of_id: nil
      repeated   = weaknesses.not_revoked.where.not repeated_of_id: nil

      if present.any?
        pdf.start_new_page

        put_bic_page_header_on pdf, I18n.t('conclusion_review.bic.weaknesses.title')

        present.reorder(risk: :desc, priority: :desc, review_code: :asc).each do |weakness|
          put_bic_weakness_on pdf, weakness, number += 1
        end
      end

      if repeated.any?
        pdf.start_new_page

        put_bic_page_header_on pdf, I18n.t('conclusion_review.bic.repeated_weaknesses.title')

        repeated.reorder(risk: :desc, priority: :desc, review_code: :asc).each do |weakness|
          put_bic_weakness_on pdf, weakness, number += 1
        end
      end
    end

    def put_bic_weakness_on pdf, weakness, number
      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t(
        'conclusion_review.bic.weaknesses.plan', number: number
      ), style: :bold, size: PDF_FONT_SIZE * 1.2

      pdf.font_size PDF_FONT_SIZE * 0.9 do
        data          = bic_weakness_data weakness
        widths        = bic_weakness_data_column_widths pdf
        table_options = pdf.default_table_options widths

        pdf.table data, table_options.merge(row_colors: %w(ffffff)) do
          row(0).style(
            background_color: 'cccccc',
            padding:          [
              (PDF_FONT_SIZE * 0.5).round,
              (PDF_FONT_SIZE * 0.3).round
            ]
          )
        end
      end
    end

    def put_bic_images_on pdf
      number = 0

      review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          weaknesses = if kind_of? ConclusionFinalReview
                         coi.final_weaknesses
                       else
                         coi.weaknesses
                       end

          weaknesses = bic_exclude_regularized_findings weaknesses

          weaknesses.not_revoked.sort_for_review.each do |weakness|
            put_bic_image_on pdf, weakness, number += 1
          end
        end
      end
    end

    def put_bic_images_by_risk_and_repetition_on pdf
      number     = 0
      weaknesses = if kind_of? ConclusionFinalReview
                     review.final_weaknesses
                   else
                     review.weaknesses
                   end

      weaknesses = bic_exclude_regularized_findings weaknesses
      present    = weaknesses.not_revoked.where repeated_of_id: nil
      repeated   = weaknesses.not_revoked.where.not repeated_of_id: nil

      present.reorder(risk: :desc, priority: :desc, review_code: :asc).each do |weakness|
        put_bic_image_on pdf, weakness, number += 1
      end

      if repeated.any?
        repeated.reorder(risk: :desc, priority: :desc, review_code: :asc).each do |weakness|
          put_bic_image_on pdf, weakness, number += 1
        end
      end
    end

    def put_bic_image_on pdf, weakness, number
      if weakness.image_model
        pdf.start_new_page

        pdf.text I18n.t(
          'conclusion_review.bic.images.plan', number: number
        ), style: :bold, size: PDF_FONT_SIZE * 1.2

        pdf.move_down PDF_FONT_SIZE

        pdf.image weakness.image_model.image.path, position: :center,
          fit: [pdf.bounds.width, pdf.bounds.height - PDF_FONT_SIZE * 3]
      end
    end

    def bic_weakness_data_column_widths pdf
      [30, 70].map { |width| pdf.percent_width width }
    end

    def bic_weakness_data weakness
      [
        [
          "<b>#{Weakness.human_attribute_name('title').upcase}</b>",
          "<b>#{weakness.title}</b>"
        ],
        [
          Weakness.human_attribute_name('description').upcase,
          weakness.description
        ],
        [
          Weakness.human_attribute_name('effect').upcase,
          weakness.effect
        ],
        [
          Weakness.human_attribute_name('risk').upcase,
          weakness.risk_text
        ],
        [
          Weakness.human_attribute_name('state').upcase,
          bic_weakness_state(weakness)
        ],
        [
          Weakness.human_attribute_name('audit_recommendations').upcase,
          weakness.audit_recommendations
        ],
        [
          Weakness.human_attribute_name('follow_up_date').upcase,
          weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-'
        ],
        [
          Weakness.human_attribute_name('answer').upcase,
          weakness.answer
        ],
        [
          I18n.t('conclusion_review.bic.weaknesses.responsible'),
          bic_weakness_responsible(weakness)
        ],
        ([
          Weakness.human_attribute_name('audit_comments').upcase,
          weakness.audit_comments
        ] if weakness.audit_comments.present?),
        ([
          I18n.t('finding.repeated_ancestors').upcase,
          weakness.repeated_of.to_s
        ] if weakness.repeated_of)
      ].compact
    end

    def bic_weakness_state weakness
      text = weakness.state_text

      if weakness.implemented_audited?
        "<color rgb='008000'><b>#{text}</b></color>"
      else
        text
      end
    end

    def bic_weakness_responsible weakness
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

    def put_bic_page_header_on pdf, text
      pdf.font_size PDF_FONT_SIZE * 1.25 do
        table_options = pdf.default_table_options [pdf.percent_width(100)]
        header_data   = [[
          content:          "<color rgb='ffffff'><b>#{text}</b></color>",
          align:            :center,
          background_color: '17365d'
        ]]

        pdf.table header_data, table_options
      end
    end

    def put_bic_subtitle_on pdf, text
      pdf.font_size PDF_FONT_SIZE * 0.9 do
        table_options = pdf.default_table_options [pdf.percent_width(100)]
        header_data   = [[
          content: "<b>#{text}</b>",
        ]]

        pdf.table header_data, table_options
      end
    end

    def put_bic_review_data_on pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.font_size PDF_FONT_SIZE * 0.9 do
        widths        = bic_review_data_column_widths pdf
        table_options = pdf.default_table_options widths

        pdf.table bic_review_data, table_options.merge(row_colors: %w(ffffff))
      end
    end

    def put_bic_review_text_data_on pdf
      [
        [
          "<b>#{Review.human_attribute_name 'description'}</b>",
          review.description
        ],
        [
          "<b>#{I18n.t 'conclusion_review.bic.review.applied_procedures'}</b>",
          applied_procedures
        ],
        ([
          "<b>#{self.class.human_attribute_name 'scope'}</b>",
          scope
        ] if scope.present?),
        ([
          "<b>#{I18n.t 'conclusion_review.bic.review.observations'}</b>",
          observations
        ] if observations.present?),
        ([
          "<b>#{self.class.human_attribute_name 'reference'}</b>",
          reference
        ] if reference.present?),
        [
          "<b>#{I18n.t 'conclusion_review.bic.review.conclusion'}</b>",
          conclusion
        ],
        ([
          "<b>#{self.class.human_attribute_name 'main_recommendations'}</b>",
          main_recommendations
        ] if main_recommendations.present?)
      ].compact.each do |title, content|
        pdf.font_size PDF_FONT_SIZE * 0.9 do
          pdf.move_down PDF_FONT_SIZE
          put_bic_subtitle_on pdf, title

          pdf.move_down PDF_FONT_SIZE
          pdf.text content, inline_format: true, align: :justify
        end
      end
    end

    def put_bic_review_score_on pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.font_size PDF_FONT_SIZE * 0.9 do
        widths        = bic_review_data_column_widths pdf
        table_options = pdf.default_table_options widths

        pdf.table bic_review_score_data, table_options.merge(
          row_colors: %w(ffffff)
        )
      end
    end

    def bic_review_data_column_widths pdf
      [30, 30, 40].map { |width| pdf.percent_width width }
    end

    def bic_review_data
      [
        [
          {
            content: [
              I18n.t('conclusion_review.bic.review.subject'),
              "<b>#{review.plan_item.project}</b>"
            ].join(': '),
            size: PDF_FONT_SIZE * 0.95
          },
          {
            content: [
              I18n.t('review.user_assignment.type_auditor'),
              bic_review_auditors_text
            ].join(': '),
            size:    PDF_FONT_SIZE * 0.85
          },
          {
            content: "<b>#{review.identification}</b>",
            align:   :center,
            size:    PDF_FONT_SIZE * 0.95
          }
        ],
        [
          {
            content: [
              ReviewUserAssignment.human_attribute_name('owner'),
              bic_review_owners_text
            ].join(': '),
            size:    PDF_FONT_SIZE * 0.85
          },
          {
            content: I18n.t(
              'conclusion_review.bic.review.previous',
              review: bic_previous_review_text
            ),
            align:   :center,
            size:    PDF_FONT_SIZE * 0.85
          },
          {
            content: I18n.t(
              'conclusion_review.bic.review.revision',
              start: bic_review_start_date,
              end:   bic_review_end_date
            ),
            align:   :center,
            size:    PDF_FONT_SIZE * 0.85
          }
        ]
      ].compact
    end

    def bic_review_score_data
      [
        [
          {
            content: [
              I18n.t('conclusion_review.bic.review.score'),
              "<b>#{I18n.t "score_types.#{review.score_array.first}"}</b>"
            ].join("\n"),
            colspan: 3,
            align:   :center,
            size:    PDF_FONT_SIZE
          }
        ]
      ].compact
    end

    def bic_review_auditors_text
      supervisors = review.review_user_assignments.select &:supervisor?
      auditors    = review.review_user_assignments.select &:auditor?

      (supervisors | auditors).map(&:user).map(&:full_name).join '; '
    end

    def bic_review_owners_text
      assignments = review.review_user_assignments.select &:audited?
      assignments = assignments.select &:owner if assignments.select(&:owner).any?
      names       = assignments.map(&:user).map do |u|
        u.full_name_with_function issue_date
      end

      names.join '; '
    end

    def bic_previous_review_text
      if previous_identification.present? && previous_date.present?
        [
          previous_identification,
          "(#{I18n.l previous_date})"
        ].join ' '
      elsif previous_identification.present?
        previous_identification
      elsif previous = review.previous
        [
          previous.identification,
          "(#{I18n.l previous.conclusion_final_review.issue_date})"
        ].join ' '
      else
        '-'
      end
    end

    def bic_review_start_date
      date = review.opening_interview&.start_date

      date ? I18n.l(date, format: :minimal) : '--/--/--'
    end

    def bic_review_end_date
      I18n.l issue_date, format: :minimal
    end

    def bic_cover_column_widths pdf
      [80, 20].map { |width| pdf.percent_width width }
    end

    def bic_cover_data
      [
        [
          content: I18n.t('conclusion_review.bic.cover.title_html',
            identification: review.identification,
            space:          Prawn::Text::NBSP
          ),
          colspan: 2,
          align:   :center
        ],
        [
          {
            content: I18n.t('conclusion_review.bic.cover.to_html'),
            valign:  :center
          },
          {
            content: I18n.t('conclusion_review.bic.cover.date_html', date: I18n.l(issue_date)),
            align:   :center
          }
        ],
        [
          {
            content: I18n.t('conclusion_review.bic.cover.from_html'),
            valign:  :center
          },
          {
            content:          bic_cover_final_text,
            align:            :center,
            background_color: '17365d'
          }
        ],
        [
          content: I18n.t('conclusion_review.bic.cover.ref_html',
            identification: review.identification,
            project:        review.plan_item.project,
            space:          Prawn::Text::NBSP
          ),
          colspan: 2,
          valign:  :center
        ]
      ]
    end

    def bic_cover_final_text
      if kind_of? ConclusionFinalReview
        I18n.t 'conclusion_review.bic.cover.final_html'
      else
        I18n.t 'conclusion_review.bic.cover.draft_html'
      end
    end
end
