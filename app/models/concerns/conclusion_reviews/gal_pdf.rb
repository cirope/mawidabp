module ConclusionReviews::GalPdf
  extend ActiveSupport::Concern

  def gal_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait, footer: false, hide_brand: true

    put_gal_tmp_reviews_code
    put_default_watermark_on pdf
    put_gal_header_on        pdf, organization
    put_gal_cover_on         pdf
    put_executive_summary_on pdf, organization
    put_detailed_review_on   pdf, organization
    put_annex_on             pdf, organization, options

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_gal_header_on pdf, organization
      hide_logo = review.business_unit_type.hide_review_logo

      pdf.add_review_header organization, nil, nil, hide_logo: hide_logo
      pdf.add_page_footer
    end

    def put_gal_cover_on pdf
      items_font_size = PDF_FONT_SIZE * 1.5
      business_unit_label =
        review.business_unit.business_unit_type.business_unit_label
      business_unit_title =
        "#{business_unit_label}: #{review.business_unit.name}"
      issue_date_title    =
        I18n.t('conclusion_review.issue_date_title').downcase.camelize

      pdf.move_down PDF_FONT_SIZE * 8
      pdf.text "#{business_unit_title}\n", size: (PDF_FONT_SIZE * 2.5).round,
        align: :center
      pdf.move_down PDF_FONT_SIZE * 4

      if review.business_unit.business_unit_type.project_label.present?
        project_label = review.business_unit.business_unit_type.project_label

        pdf.add_description_item project_label, review.plan_item.project,
          0, false, items_font_size
        pdf.move_down PDF_FONT_SIZE * 2
      end

      pdf.add_description_item ::Review.model_name.human, review.identification,
        0, false, items_font_size
      pdf.add_description_item issue_date_title, I18n.l(issue_date),
        0, false, items_font_size

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text I18n.t('conclusion_review.executive_summary.review_author'),
        size: items_font_size
    end

    def put_executive_summary_on pdf, organization
      title           = I18n.t 'conclusion_review.executive_summary.title'
      use_alt_project = review.business_unit_type.independent_identification
      project_label   = use_alt_project ? 'project_alt' : 'project'
      project_title   = I18n.t "conclusion_review.executive_summary.#{project_label}"
      project         = review.plan_item.project

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text "#{project_title} <b>#{project}</b>", inline_format: true

      put_risk_exposure_on pdf
      put_gal_score_on     pdf

      put_main_weaknesses_on pdf

      if show_observations_on_top? organization
        put_observations_on pdf
      end

      unless show_review_best_practice_comments? organization
        put_other_weaknesses_on  pdf
      end

      if show_scope_detail?
        title = I18n.t 'conclusion_review.scope_detail.title'

        pdf.start_new_page
        pdf.add_title title, (PDF_FONT_SIZE).round, :center
        pdf.move_down PDF_FONT_SIZE * 2

        put_scope_detail_table_on pdf
      end
    end

    def put_detailed_review_on pdf, organization
      title  = I18n.t 'conclusion_review.detailed_review.title'
      legend = I18n.t 'conclusion_review.detailed_review.legend'

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text legend, align: :justify, style: :italic

      put_review_survey_on       pdf
      put_detailed_weaknesses_on pdf, organization
      put_observations_on        pdf unless show_observations_on_top? organization
      put_recipients_on pdf
    end

    def put_annex_on pdf, organization, options
      title  = I18n.t 'conclusion_review.annex.title'
      legend = I18n.t 'conclusion_review.annex.legend'

      pdf.start_new_page
      pdf.add_title title, (PDF_FONT_SIZE * 2).round, :center
      pdf.move_down PDF_FONT_SIZE * 2

      pdf.text legend, align: :justify

      put_conclusion_options_on pdf
      put_workflow_text_on      pdf, organization
      put_review_scope_on       pdf, organization, options
      put_staff_on              pdf
      put_sectors_on            pdf
    end

    def put_conclusion_options_on pdf
      text = CONCLUSION_OPTIONS.map(&:upcase).join ' - '

      pdf.move_down PDF_FONT_SIZE
      pdf.text text, align: :center, style: :bold
    end

    def put_workflow_text_on pdf, organization
      workflow_text = I18n.t 'conclusion_review.annex.workflow_text'

      if show_review_best_practice_comments? organization
        pdf.move_down PDF_FONT_SIZE * 2
        pdf.text workflow_text, align: :justify
        pdf.move_down PDF_FONT_SIZE * 2
      end
    end

    def put_review_scope_on pdf, organization, options
      if show_review_best_practice_comments? organization
        pdf.move_down PDF_FONT_SIZE
        put_best_practice_comments_table_on pdf
      elsif collapse_control_objectives
        pdf.move_down PDF_FONT_SIZE
        put_collapsed_control_objective_items_table_on pdf
      else
        pdf.move_down PDF_FONT_SIZE
        put_control_objective_items_table_on pdf, brief: options[:brief]

        unless options[:brief]
          pdf.move_down PDF_FONT_SIZE
          put_control_objective_items_reference_on pdf, organization
        end
      end
    end

    def put_staff_on pdf
      title = I18n.t 'conclusion_review.annex.staff'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      review.review_user_assignments.select(&:in_audit_team?).each do |rua|
        text = "• #{rua.type_text}: #{rua.user.informal_name}"

        pdf.indent(PDF_FONT_SIZE) { pdf.text text }
      end
    end

    def put_sectors_on pdf
      title = self.class.human_attribute_name 'sectors'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      pdf.text sectors, align: :justify
    end

    def put_best_practice_comments_table_on pdf
      row_data = best_practice_comments_row_data

      if row_data.present?
        data          = row_data.insert 0, best_practice_comment_column_headers
        column_widths = best_practice_comment_column_widths pdf
        table_options = pdf.default_table_options column_widths

        pdf.font_size PDF_FONT_SIZE do
          pdf.table data, table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end
    end

    def put_collapsed_control_objective_items_table_on pdf
      row_data = collapsed_control_objectives_row_data

      if row_data.present?
        data          = row_data.insert 0, control_objective_column_headers
        column_widths = control_objective_column_widths pdf
        table_options = pdf.default_table_options column_widths

        pdf.font_size PDF_FONT_SIZE do
          pdf.table data, table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end
    end

    def put_control_objective_items_table_on pdf, brief: false
      row_data = control_objectives_row_data brief, scope_detail: false

      if row_data.present?
        data          = row_data.insert 0, control_objective_column_headers
        column_widths = control_objective_column_widths pdf
        table_options = pdf.default_table_options column_widths

        pdf.font_size PDF_FONT_SIZE do
          pdf.table data, table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end
    end

    def put_scope_detail_table_on pdf
      row_data = control_objectives_row_data true, scope_detail: true

      if row_data.present?
        column_widths                              = control_objective_column_widths pdf
        table_options                              = pdf.default_table_options column_widths
        table_options[:cell_style][:border_widths] = [0, 0, 1, 0]
        table_options[:row_colors]                 = ['ffffff']

        pdf.font_size PDF_FONT_SIZE do
          pdf.table row_data, table_options.merge(header: false)
        end
      end
    end

    def put_control_objective_items_reference_on pdf, organization
      count = 0

      review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          put_control_objective_item_reference_on pdf, organization, coi, count += 1

          pdf.move_down PDF_FONT_SIZE
        end
      end
    end

    def put_control_objective_item_reference_on pdf, organization, coi, index
      control_attributes = %i(control)

      if show_tests? organization
        control_attributes += %i(design_tests compliance_tests sustantive_tests)
      end

      pdf.text "<sup>(#{index})</sup> <b>#{coi.control_objective_text}</b>",
        inline_format: true, size: (PDF_FONT_SIZE * 1.1).round, align: :justify

      control_attributes.each do |attr_name|
        if coi.control.send(attr_name).present?
          pdf.add_description_item Control.human_attribute_name(attr_name),
            coi.control.send(attr_name), 0, false, PDF_FONT_SIZE
        end
      end
    end

    def put_review_survey_on pdf
      title = ::Review.human_attribute_name 'survey'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      pdf.text review.survey, align: :justify
    end

    def put_detailed_weaknesses_on pdf, organization
      title = Weakness.model_name.human count: 0
      show  = if show_review_best_practice_comments?(organization)
                %w(repeated_review control_objective_title template_code)
              else
                %w(repeated_review)
              end

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      put_weakness_details_on pdf, all_weaknesses,
        show: show + ['estimated_follow_up'],
        hide: %w(audited)
    end

    def put_observations_on pdf
      if observations.present?
        title = self.class.human_attribute_name 'observations'

        pdf.move_down PDF_FONT_SIZE * 2
        pdf.add_title title, (PDF_FONT_SIZE * 1.75).round
        pdf.move_down PDF_FONT_SIZE
        pdf.text observations, align: :justify, inline_format: true
      end
    end

    def put_recipients_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.text recipients, align: :justify, inline_format: true
    end

    def put_risk_exposure_on pdf
      risk_exposure_text = I18n.t(
        'conclusion_review.executive_summary.risk_exposure',
        risk: review.risk_exposure
      )

      pdf.move_down PDF_FONT_SIZE

      pdf.table [[risk_exposure_text]], {
        width:      pdf.percent_width(100),
        cell_style: {
          align:         :justify,
          inline_format: true,
          border_width:  1,
          padding:       [5, 10, 5, 10]
        }
      }
    end

    def put_gal_score_on pdf
      score_title = I18n.t 'conclusion_review.executive_summary.score'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title score_title, (PDF_FONT_SIZE * 1.75).round
      pdf.move_down PDF_FONT_SIZE

      cursor = pdf.cursor

      put_gal_score_table_on pdf
      pdf.move_cursor_to cursor
      put_evolution_table_on pdf

      pdf.move_down PDF_FONT_SIZE
      pdf.add_description_item "(*) #{self.class.human_attribute_name 'evolution_justification'}",
        evolution_justification, 0, false
    end

    def put_gal_score_table_on pdf
      widths        = gal_score_details_column_widths pdf
      table_options = pdf.default_table_options widths
      data          = [
        gal_score_details_column_data
      ]

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data, table_options do
          row(0).style(
            padding: [
              (PDF_FONT_SIZE * 0.5).round,
              (PDF_FONT_SIZE * 0.3).round
            ]
          )
        end
      end
    end

    def put_evolution_table_on pdf
      widths        = [pdf.percent_width(15)]
      table_options = pdf.default_table_options widths
      data          = [
        [I18n.t('conclusion_review.executive_summary.evolution')],
        [pdf_score_image_row(get_evolution_image)]
      ]

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data, table_options.merge(position: :right) do
          row(0).style(
            padding: [
              (PDF_FONT_SIZE * 0.5).round,
              (PDF_FONT_SIZE * 0.3).round
            ]
          )
        end
      end
    end

    def put_main_weaknesses_on pdf
      title = I18n.t 'conclusion_review.executive_summary.main_weaknesses'

      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round

      if main_weaknesses_text.present?
        put_main_weaknesses_text_on pdf
      else
        put_main_weaknesses_details_on pdf
      end
    end

    def put_main_weaknesses_text_on pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.text main_weaknesses_text, align: :justify, inline_format: true

      if corrective_actions.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title self.class.human_attribute_name('corrective_actions'),
          (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE
        pdf.text corrective_actions, align: :justify, inline_format: true
      end
    end

    def put_main_weaknesses_details_on pdf
      weaknesses = main_weaknesses

      put_weakness_details_on pdf, weaknesses,
        show: %w(estimated_follow_up),
        hide: [
          'audited',
          'audit_recommendations',
          'audit_comments',
          'internal_control_components'
        ]
    end

    def put_weakness_details_on pdf, weaknesses, hide: [], show: []
      if weaknesses.any?
        weaknesses.each do |f|

          coi = f.control_objective_item

          if show.include? 'control_objective_title'
            put_control_objective_title_on pdf, coi
          end

          def f.tmp_review_code=(code); @tmp_review_code = code; end
          def f.tmp_review_code; @tmp_review_code; end

          f.tmp_review_code = @__tmp_review_codes[f.id]

          pdf.move_down PDF_FONT_SIZE
          pdf.text coi.finding_pdf_data(f, hide: hide, show: show),
            align: :justify, inline_format: true
        end
      else
        put_no_weakness_legend_on pdf
      end
    end

    def put_control_objective_title_on pdf, control_objective_item
      unless @__last_control_objective_showed == control_objective_item.id
        options = { align: :justify, inline_format: true }
        bp      = control_objective_item.best_practice
        pc_name = control_objective_item.process_control.name
        co_text = control_objective_item.control_objective_text

        pdf.move_down PDF_FONT_SIZE

        unless @__last_best_practice_showed == bp.id
          pdf.text "<u><b>#{bp.name.upcase}</b></u>", options

          @__last_best_practice_showed = bp.id
        end

        pdf.text "<u><b>#{pc_name} (#{co_text})</b></u>", options

        @__last_control_objective_showed = control_objective_item.id
      end
    end

    def put_other_weaknesses_on pdf
      title      = I18n.t 'conclusion_review.executive_summary.other_weaknesses'
      weaknesses = other_weaknesses

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.75).round

      if weaknesses.any? || assumed_risk_weaknesses.any?
        put_other_not_assumed_risk_weaknesses_on pdf
        put_assumed_risk_weaknesses_on           pdf
      else
        put_no_weakness_legend_on pdf
      end
    end

    def put_no_weakness_legend_on pdf
      legend = I18n.t 'conclusion_review.executive_summary.no_weaknesses'

      pdf.move_down PDF_FONT_SIZE
      pdf.text legend, align: :justify
      pdf.move_down PDF_FONT_SIZE
    end

    def put_other_not_assumed_risk_weaknesses_on pdf
      if other_not_assumed_risk_weaknesses.any?
        other_not_assumed_risk_weaknesses.each do |w|
          put_short_weakness_on pdf, w, show_risk: true
        end
      end
    end

    def put_assumed_risk_weaknesses_on pdf
      weaknesses = assumed_risk_weaknesses

      if weaknesses.any?
        title =
          I18n.t 'conclusion_review.executive_summary.assumed_risk_weaknesses'

        pdf.move_down PDF_FONT_SIZE
        pdf.add_title title, (PDF_FONT_SIZE * 1.3).round
        pdf.move_down PDF_FONT_SIZE

        weaknesses.each do |w|
          put_short_weakness_on pdf, w
        end
      end
    end

    def put_short_weakness_on pdf, weakness, show_risk: false
      show_origination_date =
        weakness.repeated_ancestors.present? &&
        weakness.origination_date.present?

      origination_date = if show_origination_date
                           I18n.l weakness.origination_date
                         else
                           I18n.t 'conclusion_review.new_origination_date'
                         end
      state_text = [
        Weakness.human_attribute_name('state'), weakness.state_text
      ].join(': ')
      risk_text = [
        Weakness.human_attribute_name('risk'), weakness.risk_text
      ].join(': ')
      origination_date_text = [
        Weakness.human_attribute_name('origination_date'), origination_date
      ].join(': ')
      text = [
        @__tmp_review_codes[weakness.id],
        weakness.title,
        state_text,
        (risk_text if show_risk),
        origination_date_text
      ].compact.join(' - ')

      pdf.indent PDF_FONT_SIZE do
        pdf.text "• #{text}"
      end
    end

    def main_weaknesses
      _weaknesses = weaknesses.not_revoked.not_assumed_risk.with_high_risk

      gal_sort_weaknesses_by_review_code _weaknesses
    end

    def other_weaknesses
      _weaknesses = weaknesses.not_revoked.not_assumed_risk.with_other_risk

      gal_sort_weaknesses_by_review_code _weaknesses
    end

    def put_gal_tmp_reviews_code
      weaknesses.not_revoked.sort_by_code.each do |weakness|
        @__tmp_review_code  ||= "#{weakness.prefix}#{'%.3d' % 0}"
        @__tmp_review_codes ||= {}

        @__tmp_review_codes[weakness.id] ||= (@__tmp_review_code = @__tmp_review_code.next)
      end
    end

    def gal_sort_weaknesses_by_review_code weaknesses
      id_keys = @__tmp_review_codes.keys

      weaknesses.sort do |w1, w2|
        id_keys.index(w1.id) <=> id_keys.index(w2.id)
      end
    end

    def other_not_assumed_risk_weaknesses
      risks      = [Finding.risks[:medium], Finding.risks[:low]]
      priorities = [Finding.priorities[:low]]

      weaknesses.not_revoked.not_assumed_risk.where(risk: risks, priority: priorities).sort_by_code
    end

    def assumed_risk_weaknesses
      weaknesses.assumed_risk
    end

    def all_weaknesses
      gal_sort_weaknesses_by_review_code weaknesses.not_revoked
    end

    def weaknesses
      if kind_of? ConclusionFinalReview
        review.final_weaknesses
      else
        review.weaknesses
      end
    end

    def collapsed_control_objectives_row_data
      row_data      = []
      image_options = { vposition: :top, border_widths: [1, 0, 1, 0] }
      best_comment  = CONCLUSION_OPTIONS.first

      review.grouped_control_objective_items.each do |process_control, cois|
        if cois.all? { |coi| coi.auditor_comment == best_comment }
          row_data << satisfactory_process_control_row(process_control, image_options)
        else
          row_data << [
            { content: "<b>#{process_control.name}</b>", colspan: 3 }
          ]

          row_data += expanded_control_objective_rows(cois, image_options)
        end
      end

      row_data
    end

    def control_objectives_row_data brief, scope_detail: false
      count         = 0
      row_data      = []
      image_options = { vposition: :top, border_widths: [1, 0, 1, 0] }

      review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          text  = if scope_detail
                    coi.control_objective_text.lines.first.upcase
                  else
                    coi.control_objective_text
                  end

          image = CONCLUSION_SCOPE_IMAGES[coi.auditor_comment] ||
            'scope_not_apply.png'

          row_data << [
            brief ? text : "<sup>(#{count += 1})</sup> #{text}",
            pdf_score_image_row(image, fit: [12, 12]).merge(image_options),
            {
              content:       coi.auditor_comment&.upcase,
              border_widths: [1, 1, 1, 0]
            }
          ]
        end
      end

      row_data
    end

    def best_practice_comments_row_data
      row_data      = []
      image_options = { vposition: :top, border_widths: [1, 0, 1, 0] }
      grouped_cois  = review.grouped_control_objective_items_by_best_practice

      grouped_cois.each do |best_practice, cois|
        bpc = review.best_practice_comments.detect do |_bpc|
          _bpc.best_practice_id == best_practice.id
        end

        if bpc
          image = CONCLUSION_SCOPE_IMAGES.fetch(bpc.auditor_comment) do
            'scope_not_apply.png'
          end

          row_data << [
            best_practice.name,
            pdf_score_image_row(image, fit: [12, 12]).merge(image_options),
            {
              content:       bpc.auditor_comment&.upcase,
              border_widths: [1, 1, 1, 0]
            }
          ]
        end
      end

      row_data
    end

    def control_objective_column_headers
      [
        "<b>#{I18n.t 'conclusion_review.annex.scope_column'}</b> ",
        { content: "<b>#{self.class.human_attribute_name 'conclusion'}</b>", colspan: 2 }
      ]
    end

    def best_practice_comment_column_headers
      [
        "<b>#{I18n.t 'conclusion_review.annex.scope_column'}</b> ",
        { content: "<b>#{self.class.human_attribute_name 'conclusion'}</b>", colspan: 2 }
      ]
    end

    def control_objective_column_widths pdf
      [70, 4, 26].map { |percent| pdf.percent_width percent }
    end

    def best_practice_comment_column_widths pdf
      [70, 4, 26].map { |percent| pdf.percent_width percent }
    end

    def gal_score_details_column_widths pdf
      [70, 10].map do |width|
        pdf.percent_width width
      end
    end

    def gal_score_details_column_data
      image      = CONCLUSION_IMAGES[conclusion]
      score_text = [
        I18n.t('conclusion_review.executive_summary.score'), conclusion
      ].join(': ')

      [
        {
          content: score_text.upcase,
          valign:  :center,
          size:    12,
          height:  50.25,
          borders: [:left, :top, :bottom]
        },
        pdf_score_image_row(image).merge(borders: [:right, :top, :bottom])
      ]
    end

    def pdf_score_image_row image, fit: [23, 23]
      image_path = PDF_IMAGE_PATH.join(image || PDF_DEFAULT_SCORE_IMAGE)

      { image: image_path, fit: fit, position: :center, vposition: :center }
    end

    def expanded_control_objective_rows control_objective_items, image_options
      result       = []
      best_comment = CONCLUSION_OPTIONS.first

      offending_cois = control_objective_items.reject do |coi|
        coi.auditor_comment == best_comment
      end

      result += offending_control_objective_rows(offending_cois.sort, image_options)

      if control_objective_items.size > offending_cois.size
        result << satisfactory_control_objectives_row(image_options)
      end

      result
    end

    def offending_control_objective_rows control_objective_items, image_options
      control_objective_items.map do |coi|
        text  = coi.control_objective_text
        image = CONCLUSION_SCOPE_IMAGES[coi.auditor_comment] ||
          'scope_not_apply.png'

        [
          "#{Prawn::Text::NBSP * 4}#{text}",
          pdf_score_image_row(image, fit: [12, 12]).merge(image_options),
          {
            content:       coi.auditor_comment&.upcase,
            border_widths: [1, 1, 1, 0]
          }
        ]
      end
    end

    def satisfactory_process_control_row process_control, image_options
      best_comment = CONCLUSION_OPTIONS.first
      image        = CONCLUSION_SCOPE_IMAGES[best_comment]

      [
        "<b>#{process_control.name}</b>",
        pdf_score_image_row(image, fit: [12, 12]).merge(image_options),
        {
          content:       best_comment.upcase,
          border_widths: [1, 1, 1, 0]
        }
      ]
    end

    def satisfactory_control_objectives_row image_options
      best_comment = CONCLUSION_OPTIONS.first
      image        = CONCLUSION_SCOPE_IMAGES[best_comment]
      text         =
        I18n.t 'conclusion_review.annex.satisfactory_control_objective_items'

      [
        "#{Prawn::Text::NBSP * 4} #{text}",
        pdf_score_image_row(image, fit: [12, 12]).merge(image_options),
        {
          content:       best_comment.upcase,
          border_widths: [1, 1, 1, 0]
        }
      ]
    end

    def get_evolution_image
      CONCLUSION_EVOLUTION_IMAGES[[conclusion, evolution]] ||
        EVOLUTION_IMAGES[evolution]
    end

    def show_review_best_practice_comments? organization
      prefix = organization&.prefix

      SHOW_REVIEW_BEST_PRACTICE_COMMENTS &&
        ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include?(prefix)
    end

    def show_observations_on_top? organization
      ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include? organization.prefix
    end

    def show_tests? organization
      !review.show_counts? organization.prefix
    end

    def show_scope_detail?
      !show_review_best_practice_comments?(organization) &&
        !collapse_control_objectives &&
        SCOPE_DETAIL_IN_CONCLUSION_REVIEW_START &&
        review.period.start >= SCOPE_DETAIL_IN_CONCLUSION_REVIEW_START.to_date
    end
end
