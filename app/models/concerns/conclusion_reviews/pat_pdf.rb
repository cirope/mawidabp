module ConclusionReviews::PatPdf
  extend ActiveSupport::Concern

  def pat_pdf organization = nil, *args
    options = args.extract_options!.with_indifferent_access
    pdf     = Prawn::Document.create_generic_pdf :portrait, hide_brand: true, footer: false

    put_pat_cover_on     pdf, organization, brief: options[:brief]
    put_pat_watermark_on pdf

    unless options[:brief]
      @_next_prefix = 'A'
      @_next_index  = 0

      pdf.add_page_footer 10, false, I18n.t('conclusion_review.pat.footer.text')

      put_pat_weaknesses_section_on pdf
      put_pat_workflow_on           pdf if review.plan_item.sustantive?
    end

    if options[:return_object]
      pdf
    else
      pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
    end
  end

  private

    def put_pat_cover_on pdf, organization, brief: false
      pdf.add_organization_image organization

      put_pat_cover_header_on pdf, brief: brief

      if brief
        put_pat_extra_brief_info_on pdf, organization
      else
        put_pat_extra_cover_info_on pdf
        put_pat_review_owners_on    pdf
        put_pat_auditors_on         pdf
        put_pat_supervisors_on      pdf
        put_pat_signature_on        pdf
      end
    end

    def put_pat_cover_header_on pdf, brief: false
      to_text   = I18n.t 'conclusion_review.pat.cover.to'
      from_text = I18n.t 'conclusion_review.pat.cover.from',
        business_unit_types: review.business_unit_type.name

      unless brief
        pdf.text "#{Review.model_name.human} #{review.identification}\n\n",
          size: PDF_FONT_SIZE * 1.1, style: :bold, align: :right
      end

      pdf.text I18n.l(issue_date, format: :long), align: :right
      pdf.text "<i><b>#{from_text}</b></i>", inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text "<i><b>#{to_text}</b></i>", inline_format: true
    end

    def put_pat_extra_brief_info_on pdf, organization
      title = I18n.t(
        'conclusion_review.pat.cover.brief.title',
        description: review.description,
        review: review.identification
      )
      notice = I18n.t(
        'conclusion_review.pat.cover.brief.notice',
        review: review.identification,
        count: pat_pdf(organization, return_object: true).page_count
      )

      pdf.text "<u><i><b>#{title}</b></i></u>", align: :center, inline_format: true

      pdf.put_hr
      pdf.text notice, style: :bold, align: :justify, size: (PDF_FONT_SIZE * 0.8).round
      pdf.put_hr

      put_pat_brief_conclusion_on         pdf
      put_pat_brief_weaknesses_section_on pdf
      put_pat_brief_footer_on             pdf
    end

    def put_pat_brief_conclusion_on pdf
      title = I18n.t 'conclusion_review.pat.cover.conclusion', prefix: ''

      pdf.text "<b><u>#{title}</u></b>\n\n", inline_format: true
      pdf.text conclusion, style: :italic, align: :justify
    end

    def put_pat_extra_cover_info_on pdf
      method   = review.plan_item.cycle? ? :upcase : :to_s
      i18n_key = if review.plan_item.cycle?
                   'conclusion_review.pat.cover.description.cycle'
                 else
                   'conclusion_review.pat.cover.description.sustantive'
                 end

      pdf.text "\n<i>#{I18n.t(i18n_key, description: review.description).send method}</i>",
        align: :center, inline_format: true
      pdf.put_hr

      if review.plan_item.cycle?
        put_pat_cycle_cover_info_on pdf
      else
        put_pat_sustantive_cover_info_on pdf
      end
    end

    def put_pat_cycle_cover_info_on pdf
      pdf.text "<u>#{I18n.t 'conclusion_review.pat.cover.scope.cycle', prefix: '1.'}</u>\n\n",
        inline_format: true
      pdf.text applied_procedures, align: :justify

      pdf.text "\n#{I18n.t('conclusion_review.pat.cover.details').upcase}\n\n\n",
        align: :center, inline_format: true

      if additional_comments.present?
        pdf.text "\n<u>#{I18n.t 'conclusion_review.pat.cover.additional_comments'}</u>\n\n",
          inline_format: true
        pdf.text additional_comments, align: :justify
        pdf.move_down PDF_FONT_SIZE
      end

      pdf.text "<u>#{I18n.t 'conclusion_review.pat.cover.conclusion', prefix: '2.'}</u>\n\n",
        inline_format: true
      pdf.text conclusion, align: :justify
    end

    def put_pat_sustantive_cover_info_on pdf
      if review.description.present?
        pdf.text "<u><i>#{I18n.t 'conclusion_review.pat.cover.objective', prefix: 'I.'}</i></u>\n\n",
          inline_format: true
        pdf.text review.description, align: :justify
      end

      pdf.text "\n<u><i>#{I18n.t 'conclusion_review.pat.cover.scope.sustantive', prefix: 'II.'}</i></u>\n\n",
        inline_format: true
      pdf.text applied_procedures, align: :justify

      if additional_comments.present?
        pdf.text "\n<u>#{I18n.t 'conclusion_review.pat.cover.additional_comments'}</u>\n\n",
          inline_format: true
        pdf.text additional_comments, align: :justify
      end

      pdf.text "\n<u><i>#{I18n.t 'conclusion_review.pat.cover.conclusion', prefix: 'III.'}</i></u>\n\n",
        inline_format: true
      pdf.text conclusion, align: :justify
    end

    def put_pat_watermark_on pdf
      if instance_of? ConclusionDraftReview
        pdf.add_watermark ConclusionDraftReview.model_name.human
      end
    end

    def put_pat_review_owners_on pdf
      review_owners = review.review_user_assignments.where owner: true
      i18n_key      = if review.plan_item.cycle?
                        'conclusion_review.pat.cover.owners.cycle'
                      else
                        'conclusion_review.pat.cover.owners.sustantive'
                      end

      if review_owners.present?
        owners = review_owners.map do |ro|
          ro.user.full_name_with_function(issue_date)
        end

        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t(i18n_key, owners: owners.to_sentence)
      end
    end

    def put_pat_auditors_on pdf
      auditors = review.review_user_assignments.select &:auditor?

      pdf.text "\n<u><i><b>#{I18n.t 'conclusion_review.pat.cover.auditors'}</b></i></u>\n\n", inline_format: true

      auditors.each do |auditor|
        pdf.text "#{Prawn::Text::NBSP * 8}• #{auditor.user.full_name}", align: :justify
      end
    end

    def put_pat_supervisors_on pdf
      supervisors = review.review_user_assignments.select do |rua|
        rua.supervisor? || rua.manager? || rua.responsible?
      end

      pdf.text "\n<u><i><b>#{I18n.t 'conclusion_review.pat.cover.supervisors'}</b></i></u>\n\n", inline_format: true

      supervisors.each do |supervisor|
        pdf.text "#{Prawn::Text::NBSP * 8}• #{supervisor.user.full_name}", align: :justify
      end
    end

    def put_pat_signature_on pdf
      supervisors = review.review_user_assignments.select do |rua|
        rua.supervisor? || rua.manager? || rua.responsible?
      end

      pdf.move_down PDF_FONT_SIZE * 2

      add_review_signatures_table pdf, supervisors
    end

    def add_review_signatures_table pdf, review_user_assignments
      if review_user_assignments.size > 0
        column_data   = []
        column_widths = []

        review_user_assignments.each do |rua, i|
          data = [
            rua.user.informal_name,
            rua.user.function,
            I18n.t('conclusion_review.pat.cover.organization')
          ].reject(&:blank?).join "\n"

          column_data   << ["\n\n\n\n#{data}"]
          column_widths << pdf.percent_width(100.0 / review_user_assignments.size)
        end

        table_options = {
          cell_style: {
            borders:       [],
            padding:       (PDF_FONT_SIZE * 0.3).round,
            align:         :center,
            inline_format: true
          },
          column_widths: column_widths
        }

        pdf.table column_data, table_options
      end
    end

    def put_pat_brief_weaknesses_section_on pdf
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses
      filtered   = weaknesses.not_revoked.where.not risk: Finding.risks[:none]

      if filtered.any?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.cover.brief.details_title'), align: :justify

        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.cover.brief.weaknesses_title'), align: :justify

        filtered.each do |weakness|
          pdf.text "\n• #{Prawn::Text::NBSP * 2} #{weakness.brief} (#{weakness.risk_text})", align: :justify
        end
      end
    end

    def put_pat_brief_footer_on pdf
      manager = User.list.managers.not_hidden.take

      pdf.put_hr
      pdf.move_down PDF_FONT_SIZE * 8

      if manager
        pdf.text manager.informal_name, style: :italic
        pdf.text manager.function, style: :italic
      end
    end

    def put_pat_weaknesses_section_on pdf
      if pat_has_some_weakness?
        pdf.start_new_page

        pdf.text "<i><b>#{I18n.t 'conclusion_review.pat.weaknesses.title'}</b></i>",
          align: :right, inline_format: true
        pdf.text Weakness.model_name.human(count: 0).upcase, align: :center, style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        put_pat_previous_weaknesses_on  pdf
        put_pat_weaknesses_on           pdf
        put_pat_weaknesses_follow_up_on pdf
      end
    end

    def put_pat_previous_weaknesses_on pdf
      previous = review.previous

      if previous&.weaknesses&.with_pending_status&.any?
        previous_title = I18n.t(
          'conclusion_review.pat.weaknesses.previous_title',
          prefix: "#{@_next_prefix}."
        )

        pdf.text previous_title, style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        previous.weaknesses.each do |weakness|
          put_pat_previous_weakness_on pdf, weakness, (@_next_index += 1)
          pdf.move_down PDF_FONT_SIZE * 2
        end

        @_next_prefix = @_next_prefix.next
      end
    end

    def put_pat_previous_weakness_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

      if weakness.current_situation.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.current_situation'), style: :bold
        pdf.text weakness.current_situation
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.pat.weaknesses.risk', risk: weakness.risk_text), inline_format: true

      if weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def put_pat_weaknesses_on pdf
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses
      filtered   = weaknesses.not_revoked.where.not risk: Finding.risks[:none]

      if filtered.any?
        i18n_key_suffix = review.plan_item.cycle? ? 'cycle' : 'sustantive'

        pdf.text I18n.t(
          "conclusion_review.pat.weaknesses.current_title.#{i18n_key_suffix}",
          prefix: "#{@_next_prefix}.",
          year: review.period.name
        ), style: :bold

        pdf.move_down PDF_FONT_SIZE * 2

        filtered.each do |weakness|
          put_pat_weakness_on pdf, weakness, (@_next_index += 1)
          pdf.move_down PDF_FONT_SIZE * 2
        end

        @_next_prefix = @_next_prefix.next
      end
    end

    def put_pat_weakness_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

      if weakness.image_model
        pdf.move_down PDF_FONT_SIZE
        pdf.image weakness.image_model.image.path, position: :center,
          fit: [pdf.bounds.width, pdf.bounds.height - PDF_FONT_SIZE * 3]
      end

      if weakness.effect.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.effect'), style: :bold
        pdf.text weakness.effect
      end

      if weakness.audit_recommendations.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.audit_recommendations'), style: :bold
        pdf.text weakness.audit_recommendations
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.pat.weaknesses.risk', risk: weakness.risk_text), inline_format: true

      if weakness.answer.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.answer'), style: :bold
        pdf.text weakness.answer
      end

      if weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def put_pat_weaknesses_follow_up_on pdf
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses
      filtered   = weaknesses.not_revoked.where risk: Finding.risks[:none]
      assigned   = review.assigned_weaknesses

      if filtered.any? || assigned.any?
        pdf.text I18n.t(
          'conclusion_review.pat.weaknesses.follow_up',
          prefix: "#{@_next_prefix}.",
          year: review.period.name
        ), style: :bold

        pdf.move_down PDF_FONT_SIZE * 2

        filtered.each do |weakness|
          put_pat_weakness_follow_up_on pdf, weakness, (@_next_index += 1)
          pdf.move_down PDF_FONT_SIZE * 2
        end

        assigned.each do |weakness|
          put_pat_weakness_follow_up_on pdf, weakness, (@_next_index += 1)
          pdf.move_down PDF_FONT_SIZE * 2
        end

        @_next_prefix = @_next_prefix.next
      end
    end

    def put_pat_weakness_follow_up_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.pat.weaknesses.risk', risk: weakness.risk_text), inline_format: true

      if weakness.current_situation.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.current_situation'), style: :bold
        pdf.text weakness.current_situation
      end

      if weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def pat_has_some_weakness?
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

      weaknesses.not_revoked.any? ||
        (review.plan_item.sustantive? && review.previous&.final_weaknesses&.any?)
    end

    def put_pat_workflow_on pdf
      if review.workflow
        pdf.start_new_page

        pdf.text I18n.t('conclusion_review.pat.workflow.title'), align: :right, style: :bold
        pdf.move_down PDF_FONT_SIZE

        pdf.text "<u><b>#{I18n.t 'conclusion_review.pat.workflow.subtitle'}</b></u>",
          align: :center, inline_format: true
        pdf.move_down PDF_FONT_SIZE

        review.workflow.workflow_items.each_with_index do |wi, i|
          pdf.text "#{i.next}. #{wi.task}\n\n", align: :justify
        end
      end
    end
end
