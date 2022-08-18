module ConclusionReviews::PatPdf
  extend ActiveSupport::Concern

  include ActionView::Helpers::NumberHelper

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
      put_pat_annexes_on            pdf
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
      but_names = [review.business_unit_type.name] +
                  review.plan_item.auxiliar_business_unit_types.map { |aux_bu| aux_bu.business_unit_type.name }
      from_text = I18n.t 'conclusion_review.pat.cover.from', business_unit_types: but_names.to_sentence

      unless brief
        pdf.text "#{Review.model_name.human} #{review.identification}\n\n",
          size: PDF_FONT_SIZE * 1.1, style: :bold, align: :right
      end

      pdf.text I18n.l(issue_date, format: :long), align: :right
      pdf.text "<i><b>#{from_text}</b></i>", inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pat_to_text_pdf pdf
    end

    def put_pat_extra_brief_info_on pdf, organization
      title = I18n.t(
        'conclusion_review.pat.cover.brief.title',
        description: review.scope.presence || review.description,
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
      title  = review.scope.presence || review.description
      method = review.plan_item.cycle? ? :upcase : :to_s

      pdf.text "\n<i>#{title.send method}</i>", align: :center,
        inline_format: true
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

      pdf.move_down PDF_FONT_SIZE

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
            (I18n.t('conclusion_review.pat.cover.organization') if organization&.prefix == 'gpat')
          ].compact.reject(&:blank?).join "\n"

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
      filtered   = weaknesses.not_revoked

      if filtered.any?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.cover.brief.details_title'), align: :justify

        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.cover.brief.weaknesses_title'), align: :justify

        filtered.each do |weakness|
          pdf.text "\n• #{Prawn::Text::NBSP * 2} #{weakness.brief} (#{weakness.state_text})", align: :justify
        end
      end
    end

    def put_pat_brief_footer_on pdf
      manager = User.list.managers.not_hidden.take

      pdf.put_hr
      pdf.move_down PDF_FONT_SIZE * 8

      style_options = { style: :italic, align: :center }

      if manager
        pdf.text manager.informal_name, style_options
        pdf.text manager.function, style_options

        if organization&.prefix == 'gpat'
          pdf.text I18n.t('conclusion_review.pat.cover.organization'), style_options
        end
      end
    end

    def put_pat_weaknesses_section_on pdf
      if pat_has_some_weakness?
        pdf.start_new_page

        pdf.text "<i><b>#{I18n.t 'conclusion_review.pat.weaknesses.title'}</b></i>",
          align: :right, inline_format: true
        pdf.text Weakness.model_name.human(count: 0).upcase, align: :center, style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        put_pat_previous_weaknesses_on pdf
        put_pat_weaknesses_on           pdf
        put_pat_weaknesses_external_on  pdf
      end
    end

    def put_pat_previous_weaknesses_on pdf
      use_finals = kind_of? ConclusionFinalReview
      assigned   = review.assigned_weaknesses
      filtered   = assigned.not_revoked.order(sort_weaknesses_by).select do |w|
                     w.business_unit_type.external == false
                   end

      if filtered.any?
        previous_title = I18n.t(
          'conclusion_review.pat.weaknesses.previous_title',
          prefix: "#{@_next_prefix}."
        )

        pdf.text previous_title, style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        filtered.each do |weakness|
          put_pat_previous_weakness_on pdf, weakness, (@_next_index += 1)
          pdf.move_down PDF_FONT_SIZE * 2
        end

        @_next_prefix = @_next_prefix.next
      end
    end

    def put_pat_previous_weakness_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.pat.weaknesses.risk', risk: weakness.risk_text), inline_format: true

      if weakness.current_situation.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.current_situation'), style: :bold
        pdf.text weakness.current_situation, align: :justify
      end

      if weakness.implemented_audited? || weakness.failure?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.t("conclusion_review.pat.weaknesses.follow_up_date_#{Finding::STATUS.key(weakness.state)}")
      elsif weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def put_pat_weaknesses_on pdf
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses
      filtered   = weaknesses.not_revoked

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

      put_pat_issues_on pdf, weakness if weakness.issues.any?

      if weakness.effect.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.effect'), style: :bold
        pdf.text weakness.effect, align: :justify
      end

      if weakness.audit_recommendations.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.audit_recommendations'), style: :bold
        pdf.text weakness.audit_recommendations, align: :justify
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.pat.weaknesses.risk', risk: weakness.risk_text), inline_format: true

      if weakness.answer.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.answer'), style: :bold
        pdf.text weakness.answer, align: :justify
      end

      if weakness.implemented_audited? || weakness.failure?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.t("conclusion_review.pat.weaknesses.follow_up_date_#{Finding::STATUS.key(weakness.state)}")
      elsif weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def put_pat_weaknesses_external_on pdf
      use_finals = kind_of? ConclusionFinalReview
      assigned   = review.assigned_weaknesses
      filtered   = assigned.not_revoked.order(sort_weaknesses_by).select do |w|
                     w.business_unit_type.external == true
                   end

      if filtered.any?
        i18n_key_suffix = review.plan_item.cycle? ? 'cycle' : 'sustantive'

        pdf.text I18n.t(
          'conclusion_review.pat.weaknesses.external',
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

    def put_pat_issues_on pdf, weakness
      default_currency = I18n.t 'number.currency.format.unit'

      pdf.move_down PDF_FONT_SIZE
      pdf.text Issue.model_name.human(count: 0), style: :bold

      weakness.issues.each do |issue|
        amount_text = if issue.amount
                   [
                     Issue.human_attribute_name('amount'),
                     number_to_currency(issue.amount,
                                        unit: issue.currency || default_currency)
                   ].join ': '
                 end

        date_text = if issue.close_date
                 [
                   Issue.human_attribute_name('close_date'),
                   I18n.l(issue.close_date)
                 ].join ': '
               end

        description = [
          issue.customer,
          issue.entry,
          issue.operation,
          issue.comments
        ].reject(&:blank?).join ' | '

        data = [amount_text, date_text].compact.join ' - '

        space      = Prawn::Text::NBSP
        issue_line = "\n#{space * 4}• #{space * 2} #{description} (#{data})"

        pdf.text issue_line, align: :justify, size: PDF_FONT_SIZE * 0.8
      end
    end

    def pat_has_some_weakness?
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

      weaknesses.not_revoked.any? || review.assigned_weaknesses.any?
    end

    def put_pat_workflow_on pdf
      if review.workflow
        pdf.start_new_page

        number_in_annex =  pat_has_some_weakness? ? 'II' : 'I'

        pdf.text I18n.t('conclusion_review.pat.workflow.title', number: number_in_annex), align: :right, style: :bold
        pdf.move_down PDF_FONT_SIZE

        pdf.text "<u><b>#{I18n.t 'conclusion_review.pat.workflow.subtitle'}</b></u>",
          align: :center, inline_format: true
        pdf.move_down PDF_FONT_SIZE

        review.workflow.workflow_items.each_with_index do |wi, i|
          pdf.text "#{i.next}. #{wi.task}\n\n", align: :justify
        end
      end
    end

    def pat_to_text_pdf pdf
      receiver           = organization&.prefix == 'gpat' ? 'gpat_company' : 'audit_committee'
      to_text_first_line = I18n.t 'conclusion_review.pat.cover.to',
                                  receiver: I18n.t("conclusion_review.pat.cover.#{receiver}")

      pdf.text "<i><b>#{to_text_first_line}</b></i>", inline_format: true

      pdf.move_down PDF_FONT_SIZE
      if organization&.prefix == 'gpat'
        pdf.indent(14) do
          pdf.text "<i><b>#{I18n.t('conclusion_review.pat.cover.audit_committee')}</b></i>", inline_format: true
        end
      end
    end

    def put_pat_annexes_on pdf
      if annexes.any?
        pdf.start_new_page

        pdf.text Annex.model_name.human(count: 0).upcase, align: :center, style: :bold

        annexes.each_with_index do |annex, idx|
          pdf.move_down PDF_FONT_SIZE * 2
          pdf.text annex.title, style: :bold

          if annex.description.present?
            pdf.move_down PDF_FONT_SIZE
            pdf.text annex.description
          end

          if annex.image_models.any?
            pdf.move_down PDF_FONT_SIZE

            annex.image_models.each do |image_model|
              pdf.move_down PDF_FONT_SIZE
              pdf.image image_model.image.path, position: :center,
                fit: [pdf.bounds.width, pdf.bounds.height - PDF_FONT_SIZE * 3]
            end
          end

          pdf.start_new_page if idx < annexes.size - 1
        end
      end
    end

    def sort_weaknesses_by
      use_finals = kind_of? ConclusionFinalReview
      use_finals ? :draft_review_code : :review_code
    end
end
