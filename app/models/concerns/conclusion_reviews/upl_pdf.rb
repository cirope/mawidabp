module ConclusionReviews::UplPdf
  extend ActiveSupport::Concern

  def upl_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait, footer: false

    put_upl_cover_on                   pdf, organization
    put_upl_watermark_on               pdf
    put_upl_header_on                  pdf
    put_upl_weaknesses_brief_on        pdf, organization
    put_upl_control_objective_table_on pdf
    put_upl_findings_on                pdf, :weaknesses, options
    put_upl_findings_on                pdf, :oportunities, options
    put_upl_conclusion_on              pdf, options
    put_upl_finding_assignments_on     pdf
    put_upl_opening_interviews         pdf
    put_upl_review_signatures_table_on pdf

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_upl_control_objective_table_on pdf
      review.put_control_objective_table_on pdf
    end

    def put_upl_cover_on pdf, organization
      title_options     = [(PDF_FONT_SIZE * 1.5).round, :center, false]
      cover_text        = "\n\n\n\n#{::Review.model_name.human.upcase}\n\n"

      cover_bottom_text = "#{review.plan_item.business_unit.name}\n\n"
      cover_bottom_text << "#{review.plan_item.business_unit_type.name}\n\n"

      cover_bottom_text << I18n.l(issue_date, format: :long)

      pdf.add_review_header organization,
        review.identification,
        review.plan_item.project

      pdf.add_title cover_text, *title_options
      pdf.add_title cover_bottom_text, *title_options

      put_upl_recipients_on    pdf
      put_upl_review_owners_on pdf

    end

    def put_upl_watermark_on pdf
      if instance_of? ConclusionDraftReview
        pdf.add_watermark ConclusionDraftReview.model_name.human
      end
    end

    def put_upl_header_on pdf
      issue_date_title    = I18n.t 'conclusion_review.issue_date_title'
      business_unit_label =
        review.business_unit.business_unit_type.business_unit_label

      pdf.start_new_page
      pdf.add_page_footer

      pdf.add_subtitle  I18n.t 'conclusion_final_review.downloads.review_objectives', PDF_FONT_SIZE

      pdf.move_down PDF_FONT_SIZE

      pdf.text  I18n.t 'conclusion_final_review.downloads.review_objectives_description'

      unless HIDE_REVIEW_DESCRIPTION
        #pdf.add_title review.description
        #pdf.move_down PDF_FONT_SIZE
      end

      #pdf.add_description_item business_unit_label, review.business_unit.name

      pdf.move_down PDF_FONT_SIZE

      put_upl_period_title_on pdf

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

      if conclusion.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text conclusion, align: :justify, inline_format: true
      end
    end

    def put_upl_weaknesses_brief_on pdf, organization
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

      if show_weaknesses_brief?(organization) && weaknesses.not_revoked.any?
        date  = use_finals ? issue_date : Time.zone.today
        title = I18n.t 'conclusion_review.weaknesses_brief'

        pdf.add_subtitle title, PDF_FONT_SIZE, PDF_FONT_SIZE * 0.25
        pdf.move_down PDF_FONT_SIZE

        review.put_weaknesses_brief_table pdf, use_finals, date

        pdf.move_down PDF_FONT_SIZE
      end
    end

    def put_upl_findings_on pdf, type, options
      title              = I18n.t "conclusion_review.#{type}"
      use_finals         = kind_of? ConclusionFinalReview
      ordered_by_risk    = ORDER_WEAKNESSES_ON_CONCLUSION_REVIEWS_BY == 'risk'
      grouped_objectives = grouped_control_objectives options

      review_has_findings = grouped_objectives.any? do |_, cois|
        has_findings_for_review? cois, type, use_finals
      end

      if review_has_findings || (ordered_by_risk && type == :weaknesses)
        pdf.add_subtitle title, PDF_FONT_SIZE, PDF_FONT_SIZE * 0.25

        if ordered_by_risk
          put_upl_findings_by_risk_on pdf, type, use_finals
        else
          put_upl_control_objective_findings_on pdf, grouped_objectives, type, use_finals
        end
      end
    end

    def put_upl_finding_assignments_on pdf
      title = I18n.t 'conclusion_review.finding_review_assignments'

      if review.finding_review_assignments.any?
        pdf.add_subtitle title, PDF_FONT_SIZE, PDF_FONT_SIZE * 0.25

        repeated_findings = review.finding_review_assignments.map do |fra|
          "#{fra.finding.to_s} [<b>#{fra.finding.state_text}</b>]"
        end

        pdf.add_list repeated_findings, PDF_FONT_SIZE
      end
    end

    def put_upl_review_signatures_table_on pdf
      users = review.review_user_assignments.select(&:include_signature)
      users = users.sort_by { |rua| rua.assignment_type }

      pdf.move_down PDF_FONT_SIZE
      pdf.add_review_signatures_table users
    end

    def put_upl_objective_and_scopes_on pdf, grouped_control_objectives, options
      if grouped_control_objectives.present?
        objectives_and_scopes = I18n.t 'conclusion_review.objectives_and_scopes'

        pdf.add_subtitle objectives_and_scopes, PDF_FONT_SIZE, PDF_FONT_SIZE

        put_upl_control_objectives_on pdf, grouped_control_objectives
      end

      if applied_procedures.present?
        pdf.add_subtitle I18n.t('conclusion_review.applied_procedures'), PDF_FONT_SIZE
        pdf.text applied_procedures, align: :justify, inline_format: true
      end

      pdf.add_subtitle I18n.t('conclusion_review.conclusion'), PDF_FONT_SIZE

      if review.score_type == 'effectiveness'
        put_upl_score_table_on pdf unless options[:hide_score]
      elsif review.score_type == 'weaknesses'
        put_upl_score_text_on pdf unless options[:hide_score]
      elsif review.score_type == 'none'
        put_upl_no_score_text_on pdf unless options[:hide_score]
      end
    end

    def upl_recipients_margin owners
      recipients_count = recipients.to_s.lines.reject(&:blank?).size

      if (recipients_count + owners.size) < 19
        20 - recipients_count - owners.size
      else
        2
      end
    end

    def put_upl_recipients_on pdf
      audited_team = review.review_user_assignments.reject &:in_audit_team?

      if audited_team.present?
        pdf.move_down PDF_FONT_SIZE * upl_recipients_margin(audited_team)
        pdf.add_subtitle self.class.human_attribute_name('recipients'),
          PDF_FONT_SIZE, PDF_FONT_SIZE

        audited_team.each do |recipient|
          pdf.text "• #{recipient.user.full_name}", align: :justify, inline_format: true
        end
      end
    end

    def put_upl_review_owners_on pdf
      audit_team = review.review_user_assignments.select &:in_audit_team?
      margin     = audit_team.any? ? 0 : upl_recipients_margin([])

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

    def put_upl_period_title_on pdf
      title = I18n.t 'conclusion_review.audit_period_title'
      dates = I18n.t 'conclusion_review.audit_period',
                     start: I18n.l(review.plan_item.start, format: :long),
                     end:   I18n.l(review.plan_item.end,   format: :long)

      pdf.add_description_item title, dates
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
      explanation = I18n.t 'review.review_qualification_explanation'

      pdf.move_down PDF_FONT_SIZE

      review.put_score_details_table pdf
      pdf.move_down (PDF_FONT_SIZE * 0.75).round

      pdf.font_size (PDF_FONT_SIZE * 0.6).round do
        pdf.text "<i>#{explanation}</i>", align: :justify, inline_format: true
      end
    end

    def put_upl_score_text_on pdf
      review_score = review.score_array.first
      score_text   = I18n.t "score_types.#{review_score}"

      pdf.move_down PDF_FONT_SIZE
      pdf.text "<b>#{score_text.titleize}</b>",
        align: :justify, inline_format: true
      pdf.move_down PDF_FONT_SIZE
    end

    def put_upl_no_score_text_on pdf
      score_text = I18n.t 'score_types.none'

      pdf.move_down PDF_FONT_SIZE
      pdf.text "<b>#{score_text.titleize}</b>",
        align: :justify, inline_format: true
      pdf.move_down PDF_FONT_SIZE
    end

    def put_upl_control_objective_table_on pdf, control_objective_item, process_control
      return if is_last_displayed_control_objective? control_objective_item

      data = upl_control_objective_column_data_for control_objective_item,
                                                       process_control

      pdf.move_down PDF_FONT_SIZE

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options upl_finding_column_widths(pdf)

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

    def is_last_displayed_control_objective? control_objective_item
      if @__last_displayed_control_objective_id == control_objective_item.id
        true
      else
        @__last_displayed_control_objective_id = control_objective_item.id

        false
      end
    end

    def reset_last_displayed_control_objective
      @__last_displayed_control_objective_id = nil
    end

    def put_upl_findings_by_risk_on pdf, type, use_finals
      findings = if use_finals
                   review.send :"final_#{type}"
                 else
                   review.send type
                 end

      repeated = findings.not_revoked.where.not repeated_of_id: nil
      present  = findings.not_revoked.where repeated_of_id: nil

      put_upl_repeated_findings_by_risk_on pdf, repeated
      put_upl_present_findings_by_risk_on  pdf, present
    end

    def put_upl_repeated_findings_by_risk_on pdf, findings
      pdf.move_down (PDF_FONT_SIZE * 0.75).round
      pdf.add_title I18n.t('conclusion_review.repeated_findings'),
        (PDF_FONT_SIZE * 1.15).round

      if findings.any?
        put_upl_findings_sorted_by_risk_on pdf, findings
      else
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.repeated_findings_empty'),
          style: :italic
      end
    end

    def put_upl_present_findings_by_risk_on pdf, findings
      reset_last_displayed_control_objective

      pdf.move_down (PDF_FONT_SIZE * 0.75).round
      pdf.add_title I18n.t('conclusion_review.present_findings'),
        (PDF_FONT_SIZE * 1.15).round

      if findings.any?
        put_upl_findings_sorted_by_risk_on pdf, findings
      else
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.present_findings_empty'),
          style: :italic
      end
    end

    def put_upl_findings_sorted_by_risk_on pdf, findings
      findings.sort_for_review.each do |finding|
        coi = finding.control_objective_item

        put_upl_control_objective_table_on pdf, coi, coi.process_control

        pdf.move_down PDF_FONT_SIZE
        pdf.text coi.finding_pdf_data(finding), align: :justify, inline_format: true
      end
    end

    def put_upl_control_objective_findings_on pdf, grouped_control_objectives, type, use_finals
      grouped_control_objectives.each do |process_control, cois|
        has_findings = has_findings_for_review? cois, type, use_finals

        if has_findings
          cois.sort.each do |coi|
            coi_findings = coi_findings_for coi, type, use_finals

            if coi_findings.not_revoked.present?
              findings = coi_findings.not_revoked.sort_for_review

              put_upl_control_objective_table_on pdf, coi, process_control

              findings.each do |f|
                pdf.move_down PDF_FONT_SIZE
                pdf.text coi.finding_pdf_data(f), align: :justify, inline_format: true
              end
            end
          end
        end
      end
    end

    def has_findings_for_review? control_objective_items, type, use_finals
      control_objective_items.any? do |coi|
        findings = coi_findings_for coi, type, use_finals

        findings.not_revoked.present?
      end
    end

    def upl_control_objective_column_data_for control_objective_item, process_control
      caption = ControlObjective.model_name.human
      data    = []

      data << upl_finding_column_headers(process_control)
      data << ["<b>#{caption}:</b> #{control_objective_item.to_s}\n"]

      data
    end

    def upl_finding_column_headers process_control
      [
        "<b><i>#{ProcessControl.model_name.human}: #{process_control.name}</i></b>"
      ]
    end

    def upl_finding_column_widths pdf
      [pdf.percent_width(100)]
    end

    def coi_findings_for control_objective_item, type, use_finals
      if use_finals
        control_objective_item.send :"final_#{type}"
      else
        control_objective_item.send type
      end
    end

    def grouped_control_objectives options
      hide_excluded = options[:hide_control_objectives_excluded_from_score] == '1'

      review.grouped_control_objective_items(
        hide_excluded_from_score: hide_excluded
      )
    end

    def show_weaknesses_brief? organization
      ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS.include? organization&.prefix
    end

    def put_upl_opening_interviews pdf
      put_items_on pdf if review.closing_interview
    end

    def put_items_on pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.add_subtitle ClosingInterview.model_name.human

      pdf.move_down PDF_FONT_SIZE

      description_items_interview.each do |args|
        pdf.add_description_item *args
      end
      put_signatures_table_on pdf
    end

    def put_signatures_table_on pdf
      users = review.review_user_assignments.select(&:include_signature)
      users = users.sort_by { |rua| rua.assignment_type }

      pdf.move_down PDF_FONT_SIZE
    end

    def description_items_interview
      [
        [ClosingInterview.human_attribute_name('review'), review.to_s, 0, false],
        [I18n.t('closing_interviews.show.auditeds'), auditeds_text, 0, false],
        [I18n.t('closing_interviews.show.auditors'), auditors_text, 0, false],
        [ClosingInterviewUser.model_name.human(count: 0), assistants_text, 0, false],
        [ClosingInterview.human_attribute_name('interview_date'), I18n.l(review.closing_interview.interview_date), 0, false],
        [ClosingInterview.human_attribute_name('findings_summary'), review.closing_interview.findings_summary, 0, false],
        [ClosingInterview.human_attribute_name('recommendations_summary'), review.closing_interview.recommendations_summary, 0, false],
        [ClosingInterview.human_attribute_name('suggestions'), review.closing_interview.suggestions, 0, false],
        [ClosingInterview.human_attribute_name('comments'), review.closing_interview.comments, 0, false],
        [ClosingInterview.human_attribute_name('audit_comments'), review.closing_interview.audit_comments, 0, false],
        [ClosingInterview.human_attribute_name('responsible_comments'), review.closing_interview.responsible_comments, 0, false]
      ]
    end

    def auditeds_text
      review.closing_interview&.responsible_users.map(&:full_name).join '; '
    end

    def auditors_text
      review.closing_interview&.auditor_users.map(&:full_name).join '; '
    end

    def assistants_text
      review.closing_interview&.assistant_users.map(&:full_name).join '; '
    end
end
