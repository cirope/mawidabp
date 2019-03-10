module ConclusionReviews::BicPDF
  extend ActiveSupport::Concern

  def bic_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait

    put_default_watermark_on        pdf
    put_bic_header_on               pdf, organization
    put_bic_cover_on                pdf
    put_bic_review_on               pdf
    put_bic_weaknesses_on           pdf
    put_bic_weaknesses_on_review_on pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_bic_header_on pdf, organization
      font_size = PDF_HEADER_FONT_SIZE

      pdf.repeat :all do
        pdf.add_organization_image organization, font_size, factor: 0.5
        pdf.add_organization_co_brand_image organization, factor: 1

        pdf.canvas do
          coordinates = [0, pdf.bounds.top - PDF_FONT_SIZE.pt * 2]
          text        = I18n.t('conclusion_review.bic.header',
            identification: review.identification,
            date:           I18n.l(issue_date)
          )

          pdf.text_box text, at: coordinates, size: PDF_FONT_SIZE, align: :center
        end
      end
    end

    def put_bic_cover_on pdf
      pdf.font_size PDF_FONT_SIZE do
        table_options = pdf.default_table_options bic_cover_column_widths(pdf)

        pdf.table bic_cover_data, table_options.merge(row_colors: %w(ffffff))
      end

      put_bic_cover_legend_on     pdf
      put_bic_cover_recipients_on pdf

      pdf.move_down pdf.cursor - PDF_FONT_SIZE * 4
      pdf.put_hr
      pdf.text I18n.t('conclusion_review.bic.cover.footer'),
        size: PDF_FONT_SIZE * 0.6, align: :justify
    end

    def put_bic_cover_legend_on pdf
      manager_rua = review.review_user_assignments.detect(&:manager?) ||
                    review.review_user_assignments.detect(&:supervisor?)

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.bic.cover.legend'),
        size: PDF_FONT_SIZE, align: :justify

      if manager_rua
        pdf.move_down PDF_FONT_SIZE * 4
        pdf.text manager_rua.user.informal_name, size: PDF_FONT_SIZE,
          align: :right
      end
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

      put_bic_page_header_on          pdf, Review.model_name.human.upcase
      put_bic_review_data_on          pdf
      put_bic_main_recommendations_on pdf
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

          weaknesses.not_revoked.sort_for_review.each do |weakness|
            put_bic_weakness_on pdf, weakness, number += 1
          end
        end
      end

      number
    end

    def put_bic_weaknesses_on_review_on pdf
      header_text = I18n.t 'conclusion_review.bic.weaknesses.on_review'

      pdf.start_new_page
      put_bic_page_header_on pdf, header_text

      review.finding_review_assignments.each do |fra|
        put_bic_weakness_on pdf, fra.finding, nil, show_review: true
      end
    end

    def put_bic_weakness_on pdf, weakness, number, show_review: false
      pdf.move_down PDF_FONT_SIZE

      if number
        pdf.text I18n.t(
          'conclusion_review.bic.weaknesses.plan', number: number
        ), style: :bold
      end

      pdf.font_size PDF_FONT_SIZE * 0.75 do
        data          = bic_weakness_data weakness, show_review: show_review
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

    def bic_weakness_data_column_widths pdf
      [20, 80].map { |width| pdf.percent_width width }
    end

    def bic_weakness_data weakness, show_review:
      title = [
        (weakness.review.identification if show_review),
        weakness.title
      ].compact.join ' - '

      [
        [
          "<b>#{Weakness.human_attribute_name('title').upcase}</b>",
          "<b>#{title}</b>"
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
          weakness.users.select(&:can_act_as_audited?).map(&:full_name).join('; ')
        ],
        ([
          Weakness.human_attribute_name('audit_comments').upcase,
          weakness.audit_comments
        ] if weakness.audit_comments.present?)
      ].compact
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

    def put_bic_review_data_on pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.font_size PDF_FONT_SIZE * 0.75 do
        widths        = bic_review_data_column_widths pdf
        table_options = pdf.default_table_options widths

        pdf.table bic_review_data, table_options.merge(row_colors: %w(ffffff))
      end
    end

    def put_bic_main_recommendations_on pdf
      pdf.font_size PDF_FONT_SIZE * 0.75 do
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.bic.review.main_recommendations'),
          style: :bold
        pdf.move_down PDF_FONT_SIZE

        pdf.text bic_main_recommendations, align: :justify
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
              "<b>#{review.business_unit.name}</b>"
            ].join(': '),
            size: PDF_FONT_SIZE * 0.85
          },
          [
            I18n.t('review.user_assignment.type_auditor'),
            bic_review_auditors_text
          ].join(': '),
          {
            content: "<b>#{review.identification}</b>",
            align:   :center,
            size:    PDF_FONT_SIZE * 0.85
          }
        ],
        [
          [
            ReviewUserAssignment.human_attribute_name('owner'),
            review.review_user_assignments.select(&:audited?).map(&:user).map(&:full_name).join('; ')
          ].join(': '),
          {
            content: I18n.t(
              'conclusion_review.bic.review.previous',
              review: bic_previous_review_text
            ),
            align:   :center,
          },
          {
            content: I18n.t(
              'conclusion_review.bic.review.revision',
              start: bic_review_start_date,
              end:   bic_review_end_date
            ),
            align:   :center
          }
        ],
        [
          {
            content: [
              "<b>#{self.class.human_attribute_name 'objective'}</b>",
              objective
            ].join(': '),
            colspan: 3
          }
        ],
        [
          {
            content: [
              "<b>#{I18n.t 'conclusion_review.bic.review.applied_procedures'}</b>",
              applied_procedures
            ].join(': '),
            colspan: 3
          }
        ],
        ([
          {
            content: [
              "<b>#{self.class.human_attribute_name 'scope'}</b>",
              scope
            ].join(': '),
            colspan: 3
          }
        ] if scope.present?),
        ([
          {
            content: [
              "<b>#{I18n.t 'conclusion_review.bic.review.observations'}</b>",
              observations
            ].join(': '),
            colspan: 3
          }
        ] if observations.present?),
        [
          {
            content: [
              "<b>#{self.class.human_attribute_name 'reference'}</b>",
              reference
            ].join(': '),
            colspan: 3
          }
        ],
        [
          {
            content: [
              "<b>#{I18n.t 'conclusion_review.bic.review.conclusion'}</b>",
              conclusion
            ].join(': '),
            colspan: 3
          }
        ],
        [
          {
            content: [
              self.class.human_attribute_name('conclusion'),
              "<b>#{review.score_text}</b>"
            ].join("\n"),
            colspan: 3,
            align:   :center,
            size:    PDF_FONT_SIZE * 0.85
          }
        ]
      ].compact
    end

    def bic_review_auditors_text
      managers    = review.review_user_assignments.select &:manager?
      supervisors = review.review_user_assignments.select &:supervisor?
      auditors    = review.review_user_assignments.select &:auditor?


      (managers | supervisors | auditors).map(&:user).map(&:full_name).join '; '
    end

    def bic_previous_review_text
      if previous = review.previous
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

    def bic_main_recommendations
      result = ''

      review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          coi.weaknesses.not_revoked.sort_for_review.each do |w|
            result << "#{w.audit_recommendations}\r\n\r\n"
          end
        end
      end

      result
    end
end
