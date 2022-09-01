module Reviews::ScoreSheetCommon
  extend ActiveSupport::Concern

  def score_sheet_common_header organization = nil, global: false, draft: false
    pdf = Prawn::Document.create_generic_pdf :portrait

    put_score_sheet_header_on pdf, organization, global: global, draft: draft
    put_business_unit_info_on pdf
    put_period_info_on        pdf
    put_users_info_on         pdf

    pdf.add_subtitle I18n.t('review.score'), PDF_FONT_SIZE, PDF_FONT_SIZE

    put_score_details_table pdf

    pdf
  end

  def sanitized_identification
    identification.strip.sanitized_for_filename
  end

  private

    def put_score_sheet_header_on pdf, organization, global:, draft:
      pdf.add_review_header organization, identification, plan_item.project

      put_score_sheet_title pdf, global: global

      pdf.add_watermark I18n.t('pdf.draft') if draft

      pdf.move_down PDF_FONT_SIZE
    end

    def put_business_unit_info_on pdf
      business_unit_label = business_unit.business_unit_type.business_unit_label
      project_label       = business_unit.business_unit_type.project_label

      pdf.add_description_item business_unit_label, business_unit.name

      if project_label.present?
        pdf.add_description_item project_label, plan_item.project
      end
    end

    def put_period_info_on pdf
      title        = I18n.t 'review.audit_period_title'
      audit_period = I18n.t 'review.audit_period',
        start: I18n.l(plan_item.start, format: :long),
        end:   I18n.l(plan_item.end, format: :long)

      pdf.add_description_item title, audit_period
    end

    def put_users_info_on pdf
      users      = review_user_assignments.reject &:audited?
      user_names = users.map { |rua| rua.user.full_name }

      pdf.add_description_item I18n.t('review.auditors'), user_names.join('; ')
    end

    def put_score_sheet_title pdf, global:
      title = if global
                I18n.t 'review.global_score_sheet_title'
              else
                I18n.t 'review.score_sheet_title'
              end

      pdf.add_title title
    end

    def process_control_row_data process_control, effectiveness, exclude, global: false
      [
        "#{ProcessControl.model_name.human}: #{process_control}",
        ('' unless global),
        exclude ? '-' : "#{effectiveness.round}%**"
      ].compact
    end

    def control_objective_effectiveness_for control_objective_item_data
      coi_relevance_count = control_objective_item_data.inject(0.0) do |t, e|
        e[3] ? t : t + e[2]
      end

      control_objective_item_data.inject(0.0) do |t, e|
        if coi_relevance_count > 0
          e[3] ? t : t + (e[1] * e[2]) / coi_relevance_count
        else
          100.0
        end
      end
    end

    def put_risk_subtitle_on pdf
      sorted_risks  = Review.risks.sort { |r1, r2| r2[1] <=> r1[1] }
      risk_levels   = sorted_risks.map { |r| I18n.t "risk_types.#{r[0]}" }
      risk_subtitle = I18n.t 'review.weaknesses_summary',
        risks: risk_levels.to_sentence

      pdf.add_subtitle risk_subtitle, PDF_FONT_SIZE, PDF_FONT_SIZE
    end

    def put_score_sheet_notes_on pdf
      notes_title   = I18n.t 'review.notes'
      qualification = I18n.t 'review.review_qualification_explanation'
      process_notes = I18n.t 'review.process_control_qualification_explanation'
      options       = {
        font_size:     (PDF_FONT_SIZE * 0.75).round,
        inline_format: true
      }

      pdf.move_down (PDF_FONT_SIZE * 0.75).round

      pdf.font_size (PDF_FONT_SIZE * 0.6).round do
        pdf.text "<b>#{notes_title}</b>:",     options
        pdf.text "<i>* #{qualification}</i>",  options.merge(align: :justify)
        pdf.text "<i>** #{process_notes}</i>", options.merge(align: :justify)
      end
    end

    def put_review_signatures_table_on pdf
      users = review_user_assignments.select &:include_signature

      pdf.add_review_signatures_table users
    end

    def collect_process_controls
      control_objective_items.each_with_object({}) do |coi, process_controls|
        process_controls[coi.process_control.name] ||= []
        process_controls[coi.process_control.name] << [
          coi.to_s,
          coi.effectiveness || 0,
          coi.relevance     || 0,
          coi.exclude_from_score
        ]
      end
    end
end
