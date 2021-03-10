module ConclusionReviews::UplPdf
  extend ActiveSupport::Concern

  def upl_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait, footer: false, hide_brand: true

    put_upl_cover_on                       pdf, organization
    put_default_watermark_on               pdf
    put_upl_header_on                      pdf
    put_upl_conclusion_on                  pdf, options
    put_upl_process_effectiveness_table_on pdf, options
    put_upl_findings_on                    pdf, :weaknesses, options
    put_upl_findings_on                    pdf, :oportunities, options
    put_upl_applied_procedures             pdf, options
    put_default_finding_assignments_on     pdf
    put_upl_closing_interviews             pdf
    put_default_review_signatures_table_on pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_upl_cover_on pdf, organization
      title_options     = [(PDF_FONT_SIZE * 1.5).round, :center, false]

      pdf.move_down PDF_FONT_SIZE * 10
      pdf.add_title Review.model_name.human.upcase, *title_options
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title review.identification, *title_options
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title review.plan_item.business_unit.name, *title_options
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title review.plan_item.business_unit_type.name, *title_options
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title review.plan_item.business_unit&.tags.map(&:name).join, *title_options
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title I18n.l(issue_date, format: :long), *title_options
      pdf.move_down PDF_FONT_SIZE

      put_upl_recipients_on    pdf
      put_upl_review_owners_on pdf
    end

    def put_upl_header_on pdf
      issue_date_title    = I18n.t 'conclusion_review.issue_date_title'
      business_unit_label =
        review.business_unit.business_unit_type.business_unit_label

      pdf.start_new_page

      add_upl_conclusion_final_review_header pdf, organization

      pdf.move_down PDF_FONT_SIZE

      add_upl_conclusion_final_review_page_footer pdf

      pdf.add_subtitle I18n.t 'conclusion_final_review.downloads.review_objectives', PDF_FONT_SIZE
      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t 'conclusion_final_review.downloads.review_objectives_description'
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item business_unit_label, review.business_unit.name
      pdf.move_down PDF_FONT_SIZE

      put_default_period_title_on pdf

      pdf.move_down PDF_FONT_SIZE
      pdf.add_description_item issue_date_title, I18n.l(issue_date, format: :long)

      if review.business_unit.business_unit_type.project_label.present?
        project_label = review.business_unit.business_unit_type.project_label

        pdf.add_description_item project_label, review.plan_item.project
      end
    end

    def put_upl_conclusion_on pdf, options
      grouped_objectives = grouped_control_objectives options

      if options[:brief].blank?
        put_upl_objective_and_scopes_on pdf, grouped_objectives, options
      else
        pdf.add_subtitle I18n.t('conclusion_review.conclusion'), PDF_FONT_SIZE
      end
    end

    def put_upl_process_effectiveness_table_on pdf, options
      review.put_control_objective_table_on pdf unless options[:hide_score]
    end

    def put_upl_findings_on pdf, type, options
      title              = I18n.t "conclusion_review.#{type}"
      use_finals         = kind_of? ConclusionFinalReview
      grouped_objectives = grouped_control_objectives options

      review_has_findings = grouped_objectives.any? do |_, cois|
        has_findings_for_review? cois, type, use_finals
      end

      if review_has_findings || type == :weaknesses
        pdf.add_subtitle title, PDF_FONT_SIZE, PDF_FONT_SIZE * 0.25

        put_upl_control_objective_findings_on pdf, grouped_objectives, type, use_finals
      end
    end

    def put_upl_objective_and_scopes_on pdf, grouped_control_objectives, options
      if grouped_control_objectives.present?
        objectives_and_scopes = I18n.t 'conclusion_review.objectives_and_scopes'

        pdf.add_subtitle objectives_and_scopes, PDF_FONT_SIZE, PDF_FONT_SIZE

        put_upl_control_objectives_on pdf, grouped_control_objectives
      end
    end

    def put_upl_applied_procedures pdf, options
      if applied_procedures.present?
        pdf.add_subtitle I18n.t('conclusion_review.applied_procedures'), PDF_FONT_SIZE
        pdf.text applied_procedures, align: :justify, inline_format: true
      end

      pdf.add_subtitle I18n.t('conclusion_review.conclusion'), PDF_FONT_SIZE

      if conclusion.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text conclusion, align: :justify, inline_format: true
      end

      put_upl_score_table_on pdf unless options[:hide_score]
    end

    def put_upl_recipients_on pdf
      audited_team = review.review_user_assignments.reject &:in_audit_team?

      if audited_team.present?
        pdf.move_down PDF_FONT_SIZE * default_recipients_margin(audited_team)
        pdf.add_subtitle self.class.human_attribute_name('recipients'),
          PDF_FONT_SIZE, PDF_FONT_SIZE

        audited_team.each do |recipient|
          pdf.text "• #{recipient.user.full_name}", align: :justify, inline_format: true
        end
      end
    end

    def put_upl_review_owners_on pdf
      audit_team = review.review_user_assignments.select &:in_audit_team?
      margin     = audit_team.any? ? 0 : default_recipients_margin([])

      if audit_team.present?
        pdf.move_down PDF_FONT_SIZE * margin
        pdf.add_subtitle I18n.t('conclusion_review.responsibles'),
          PDF_FONT_SIZE, PDF_FONT_SIZE

        audit_team.each do |rua|
          pdf.text "• #{rua.user.full_name}", align: :justify,
            inline_format: true
        end
      end
    end

    def put_upl_control_objectives_on pdf, grouped_control_objectives
      grouped_control_objectives.each do |process_control, cois|
        coi_data              = cois.sort.map { |coi| ['• ', coi.to_s] }
        process_control_text  = "<b>#{ProcessControl.model_name.human}: "
        process_control_text << "<i>#{process_control.name}</i></b>"

        pdf.text process_control_text, align: :justify, inline_format: true

        if coi_data.present?
          pdf.indent PDF_FONT_SIZE do
            pdf.table coi_data, {
              cell_style: {
                align:        :justify,
                border_width: 0,
                padding:      [0, 0, 5, 0]
              }
            }
          end
        end
      end
    end

    def put_upl_score_table_on pdf
      explanation   = I18n.t 'review.review_qualification_explanation'
      score_global  = review.score_array.last
      title_options = [(PDF_FONT_SIZE * 1.5).round, :center, false]
      width         = pdf.bounds.width
      coordinates   = [0, pdf.y - PDF_FONT_SIZE.pt * 10]

      pdf.bounding_box coordinates, width: width do
        pdf.move_down (PDF_FONT_SIZE * 0.75).round

        pdf.add_title "#{I18n.t 'conclusion_final_review.global_effectiveness'} (#{score_global}%)",
          *title_options
          pdf.stroke_bounds
      end

      pdf.move_down (PDF_FONT_SIZE * 0.75).round

      pdf.font_size (PDF_FONT_SIZE * 0.6).round do
        pdf.text "<i>#{explanation}</i>", align: :justify, inline_format: true
      end

      pdf.move_down (PDF_FONT_SIZE * 0.75).round

      pdf.text effectiveness_notes
    end

    def put_upl_control_objective_findings_on pdf, grouped_control_objectives, type, use_finals
      grouped_control_objectives.each do |process_control, cois|
        has_findings = has_findings_for_review? cois, type, use_finals

        if has_findings
          cois.sort.each do |coi|
            coi_findings = coi_findings_for coi, type, use_finals

            if coi_findings.not_revoked.present?
              findings = coi_findings.not_revoked.sort_for_review

              put_default_control_objective_table_on pdf, coi, process_control

              findings.each do |f|
                pdf.move_down PDF_FONT_SIZE
                pdf.text coi.finding_pdf_data(f), align: :justify, inline_format: true
              end
            end
          end
        end
      end
    end

    def put_upl_closing_interviews pdf
      put_upl_closing_interview_items_on pdf if review.closing_interview
    end

    def put_upl_closing_interview_items_on pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.add_subtitle ClosingInterview.model_name.human

      pdf.move_down PDF_FONT_SIZE

      upl_description_items_interview.each do |args|
        pdf.add_description_item *args
      end
    end

    def upl_description_items_interview
      [
        [ClosingInterview.human_attribute_name('review'), review.to_s, 0, false],
        [I18n.t('closing_interviews.show.auditeds'), upl_auditeds_text, 0, false],
        [I18n.t('closing_interviews.show.auditors'), upl_auditors_text, 0, false],
        [ClosingInterviewUser.model_name.human(count: 0), upl_assistants_text, 0, false],
        [ClosingInterview.human_attribute_name('interview_date'), I18n.l(review.closing_interview.interview_date), 0, false],
        [ClosingInterview.human_attribute_name('findings_summary'), review.closing_interview.findings_summary, 0, false],
        [ClosingInterview.human_attribute_name('recommendations_summary'), review.closing_interview.recommendations_summary, 0, false],
        [ClosingInterview.human_attribute_name('suggestions'), review.closing_interview.suggestions, 0, false],
        [ClosingInterview.human_attribute_name('comments'), review.closing_interview.comments, 0, false],
        [ClosingInterview.human_attribute_name('audit_comments'), review.closing_interview.audit_comments, 0, false],
        [ClosingInterview.human_attribute_name('responsible_comments'), review.closing_interview.responsible_comments, 0, false]
      ]
    end

    def upl_auditeds_text
      review.closing_interview&.responsible_users.map(&:full_name).join '; '
    end

    def upl_auditors_text
      review.closing_interview&.auditor_users.map(&:full_name).join '; '
    end

    def upl_assistants_text
      review.closing_interview&.assistant_users.map(&:full_name).join '; '
    end

    def add_upl_conclusion_final_review_header pdf, organization
      pdf.repeat :all do
        font_size = PDF_HEADER_FONT_SIZE

        pdf.add_organization_image organization, font_size

        y_pointer = pdf.y

        pdf.canvas do
          column_width = pdf.bounds.width - font_size.pt * 2
          table_data   = upl_table_data_header

          pdf.move_down PDF_FONT_SIZE

          pdf.indent(PDF_FONT_SIZE) do
            pdf.table table_data,
              column_widths: [column_width * 0.45, column_width * 0.4, column_width * 0.15],
              cell_style: {
                align: :right,
                size: (font_size * 0.75).round
              }
          end
        end

        pdf.y = y_pointer
      end
    end

    def upl_table_data_header
      [
        [
          { content: "", rowspan: 3 }, I18n.t('conclusion_final_review.downloads.general_assistant_manager'),
          { content: I18n.t('conclusion_final_review.downloads.page_number'), rowspan: 3 }
        ],
        [I18n.t('conclusion_final_review.downloads.departmental_management')],
        [I18n.t('conclusion_final_review.downloads.departmental_assistant_manager')],
      ]
    end

    def add_upl_conclusion_final_review_page_footer pdf, font_size = 10, skip_first_page = false
      pages = skip_first_page ? -> (page) { page > 1 } : :all

      pdf.repeat pages, dynamic: true do
        pdf.canvas do
          right_margin = pdf.page.margins[:right]
          string_title = I18n.t('conclusion_final_review.downloads.pdf_page_footer_title')
          string_sheet = I18n.t('conclusion_final_review.downloads.pdf_page_footer_sheet')
          x            = pdf.bounds.right - pdf.width_of(string_title)

          pdf.stroke do
            pdf.horizontal_line (font_size * 2), pdf.bounds.width - (font_size * 2), at: (font_size.pt * 3)
          end

          pdf.draw_text string_title, at: [font_size * 4, (font_size.pt * 1.75)],
            size: (font_size * 0.75)
          pdf.draw_text string_sheet, at: [x, (font_size.pt * 1.75)],
            size: (font_size * 0.75)
        end
      end
    end
end
