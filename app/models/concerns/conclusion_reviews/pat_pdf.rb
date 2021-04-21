module ConclusionReviews::PatPdf
  extend ActiveSupport::Concern

  def pat_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait, hide_brand: true, footer: false

    put_pat_cover_on     pdf, organization
    put_pat_watermark_on pdf

    pdf.add_page_footer 10, false, I18n.t('conclusion_review.pat.footer.text')

    if pat_has_some_weakness?
      pdf.start_new_page

      pdf.text Weakness.model_name.human(count: 0).upcase, align: :center, style: :bold
      pdf.move_down PDF_FONT_SIZE * 2

      put_pat_previous_weaknesses_on pdf
      put_pat_weaknesses_on          pdf
    end

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_pat_cover_on pdf, organization
      pdf.add_organization_image organization

      put_pat_cover_header_on pdf
      put_pat_extra_cover_info_on pdf

      put_pat_review_owners_on pdf
      put_pat_auditors_on pdf
      put_pat_supervisors_on pdf
      put_pat_signature_on pdf
    end

    def put_pat_cover_header_on pdf
      to_text = I18n.t 'conclusion_review.pat.cover.to', recipients: recipients

      pdf.text "#{Review.model_name.human} #{review.identification}\n\n",
        size: PDF_FONT_SIZE * 1.1, style: :bold, align: :right
      pdf.text I18n.l(issue_date, format: :long), align: :right
      pdf.text "<i><b>#{I18n.t 'conclusion_review.pat.cover.from'}</b></i>",
        inline_format: true

      pdf.move_down PDF_FONT_SIZE

      pdf.text "<i><b>#{to_text}</b></i>", inline_format: true
    end

    def put_pat_extra_cover_info_on pdf
      business_unit_text = I18n.t(
        'conclusion_review.pat.cover.business_unit',
        business_unit: review.business_unit.name
      )

      pdf.text "\n<i>#{business_unit_text.upcase}</i>", align: :center,
        inline_format: true
      pdf.put_hr

      pdf.text "<u>#{I18n.t 'conclusion_review.pat.cover.scope'}</u>\n\n",
        inline_format: true
      pdf.text applied_procedures, align: :justify

      pdf.text "\n#{I18n.t('conclusion_review.pat.cover.details').upcase}\n\n\n",
        align: :center, inline_format: true
      pdf.text "<u>#{I18n.t 'conclusion_review.pat.cover.conclusion'}</u>\n\n",
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

      if review_owners.present?
        owners = review_owners.map do |ro|
          ro.user.full_name_with_function(issue_date)
        end

        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.cover.owners', owners: owners.to_sentence)
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
      if review_user_assignments.present?
        column_data = []
        column_widths = []

        review_user_assignments.each do |rua, i|
          data = [
            rua.user.informal_name,
            rua.user.function,
            I18n.t('conclusion_review.pat.cover.organization')
          ].reject(&:blank?).join "\n"

          column_data <<  ["\n\n\n\n#{data}"]
          column_widths << pdf.percent_width(100.0 / review_user_assignments.size)
        end

        table_options = {
          cell_style: {
            borders: [],
            padding: (PDF_FONT_SIZE * 0.3).round,
            align: :center,
            inline_format: true
          },
          width: column_widths.sum,
          column_widths: column_widths
        }

        pdf.table column_data, table_options
      end
    end

    def put_pat_previous_weaknesses_on pdf
      previous = review.previous

      if previous&.weaknesses&.with_pending_status&.any?
        pdf.text I18n.t('conclusion_review.pat.weaknesses.previous_title'), style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        previous.weaknesses.each_with_index do |weakness, i|
          put_pat_previous_weakness_on pdf, weakness, i.next
          pdf.move_down PDF_FONT_SIZE * 2
        end
      end
    end

    def put_pat_previous_weakness_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

      if weakness.answer.present?
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.current_situation'), style: :bold
        pdf.text weakness.answer
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

      if weaknesses.not_revoked.any?
        pdf.text I18n.t('conclusion_review.pat.weaknesses.current_title', year: issue_date.year), style: :bold
        pdf.move_down PDF_FONT_SIZE * 2

        weaknesses.not_revoked.each_with_index do |weakness, i|
          put_pat_weakness_on pdf, weakness, i.next
          pdf.move_down PDF_FONT_SIZE * 2
        end
      end
    end

    def put_pat_weakness_on pdf, weakness, i
      pdf.text "#{i}. #{weakness.title}\n\n", align: :justify, style: :bold
      pdf.text weakness.description, align: :justify

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

      if weakness.follow_up_date
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.pat.weaknesses.follow_up_date'), style: :bold
        pdf.text I18n.l(weakness.follow_up_date, format: :minimal)
      end
    end

    def pat_has_some_weakness?
      use_finals = kind_of? ConclusionFinalReview
      weaknesses = use_finals ? review.final_weaknesses : review.weaknesses

      weaknesses.not_revoked.any? || review.previous&.final_weaknesses&.any?
    end
end
