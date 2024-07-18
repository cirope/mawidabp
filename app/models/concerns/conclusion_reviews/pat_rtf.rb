module ConclusionReviews::PatRtf
  extend ActiveSupport::Concern

  def pat_rtf organization = nil, *args
    initialize_styles

    document = RTF::Document.new RTF::Font.new(RTF::Font::ROMAN, 'Arial')

    put_pat_cover_on_rtf document, organization

    @_next_prefix_rtf = 'A'
    @_next_index_rtf  = 0

    footer = RTF::FooterNode.new document

    footer.paragraph do |p1|
      p1 << I18n.t('conclusion_review.pat.footer.text')
    end

    document.footer = footer

    put_pat_weaknesses_section_on_rtf document
    put_pat_workflow_on_rtf           document if review.plan_item.sustantive?
    put_pat_annexes_on_rtf            document

    document.to_rtf
  end

  private

    def initialize_styles
      @styles                                 = {}
      @styles['P_ALIGN_RIGTH']                = RTF::ParagraphStyle.new
      @styles['P_ALIGN_RIGTH'].justification  = RTF::ParagraphStyle::RIGHT_JUSTIFY
      @styles['P_ALIGN_CENTER']               = RTF::ParagraphStyle.new
      @styles['P_ALIGN_CENTER'].justification = RTF::ParagraphStyle::CENTER_JUSTIFY
    end

    def style(bold: false, italic: false, underline: false, size: 1)
      style           = RTF::CharacterStyle.new
      style.bold      = bold
      style.italic    = italic
      style.underline = underline
      style.font_size = RTF_FONT_SIZE * size

      style
    end

    def put_pat_cover_on_rtf document, organization
      add_organization_image document, organization

      put_pat_cover_header_on_rtf     document
      put_pat_extra_cover_info_on_rtf document
      put_pat_review_owners_on_rtf    document
      put_pat_auditors_on_rtf         document
      put_pat_supervisors_on_rtf      document
      put_pat_signature_on_rtf        document
    end

    def add_organization_image document, organization
      organization_image = organization.image_model&.image&.thumb&.path

      if organization_image && File.exist?(organization_image)
        header = RTF::HeaderNode.new document

        header.paragraph { |n| n.image(organization_image) }

        document.header = header
      end
    end

    def put_pat_cover_header_on_rtf document
      but_names = [review.business_unit_type.name] +
                  review.plan_item.auxiliar_business_unit_types.map { |aux_bu| aux_bu.business_unit_type.name }

      header_right_identifacion = style bold: true, size: 1.1

      document.paragraph(@styles['P_ALIGN_RIGTH']) do |p1|
        p1.apply(header_right_identifacion) do |p2|
          p2 << "#{Review.model_name.human} #{review.identification}\n\n"
          p2.line_break
        end
      end

      header_right_issue_date = style

      document.paragraph(@styles['P_ALIGN_RIGTH']) do |p1|
        p1.apply(header_right_issue_date) do |p2|
          p2 << I18n.l(issue_date, format: :long)
        end
      end

      header_left = style bold: true, italic: true

      document.paragraph(header_left) do |p1|
        p1 << I18n.t('conclusion_review.pat.rtf.cover.bank')
        p1.line_break
        p1 << I18n.t('conclusion_review.pat.rtf.cover.department')
        p1.line_break
        p1 << but_names.to_sentence
        p1.line_break
        p1.line_break

        receiver           = organization&.prefix == 'gpat' ? 'gpat_company' : 'audit_committee'
        to_text_first_line = I18n.t 'conclusion_review.pat.cover.to',
                                    receiver: I18n.t("conclusion_review.pat.cover.#{receiver}")

        p1 << to_text_first_line

        if organization&.prefix == 'gpat'
          p1.line_break
          p1 << "    #{I18n.t('conclusion_review.pat.cover.audit_committee')}"
        end
      end
    end

    def put_pat_extra_cover_info_on_rtf document
      title  = review.scope.presence || review.description
      method = review.plan_item.cycle? ? :upcase : :to_s

      title_style = style italic: true

      document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
        p1.apply(title_style) do |p2|
          p2 << title.send(method)
        end
      end

      table                        = document.table(1, 1,10000, 10)
      table.border_width           = 0
      table[0][0].top_border_width = 1

      if review.plan_item.cycle?
        put_pat_cycle_cover_info_on_rtf document
      else
        put_pat_sustantive_cover_info_on_rtf document
      end
    end

    def put_pat_cycle_cover_info_on_rtf document
      title_style       = style italic: true, underline: true
      description_style = style

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.scope.cycle', prefix: '1.')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        p1 << applied_procedures
        p1.line_break
      end

      if additional_comments.present?
        document.paragraph(title_style) do |p1|
          p1 << I18n.t('conclusion_review.pat.cover.additional_comments')
          p1.line_break
        end

        document.paragraph(description_style) do |p1|
          p1 << additional_comments
          p1.line_break
        end
      end

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.conclusion', prefix: '2.')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        p1 << conclusion
        p1.line_break
      end
    end

    def put_pat_sustantive_cover_info_on_rtf document
      title_style       = style italic: true, underline: true
      description_style = style

      if review.description.present?
        document.paragraph(title_style) do |p1|
          p1 << I18n.t('conclusion_review.pat.cover.objective', prefix: 'I.')
          p1.line_break
        end

        document.paragraph(description_style) do |p1|
          p1 << review.description
          p1.line_break
        end
      end

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.scope.sustantive', prefix: 'II.')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        p1 << applied_procedures
        p1.line_break
      end

      if additional_comments.present?
        document.paragraph(title_style) do |p1|
          p1 << I18n.t('conclusion_review.pat.cover.additional_comments')
          p1.line_break
        end

        document.paragraph(description_style) do |p1|
          p1 << additional_comments
          p1.line_break
        end
      end

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.conclusion', prefix: 'III.')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        p1 << conclusion
        p1.line_break
      end
    end

    def put_pat_review_owners_on_rtf document
      description_style = style

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

        document.paragraph(description_style) do |p1|
          p1 << I18n.t(i18n_key, owners: owners.to_sentence)
          p1.line_break
        end
      end
    end

    def put_pat_auditors_on_rtf document
      title_style       = style italic: true, underline: true, bold: true
      description_style = style

      auditors = review.review_user_assignments.select &:auditor?

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.auditors')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        auditors.each do |auditor|
          p1 << "#{Prawn::Text::NBSP * 8}• #{auditor.user.full_name}"
          p1.line_break
        end
      end
    end

    def put_pat_supervisors_on_rtf document
      title_style       = style italic: true, underline: true, bold: true
      description_style = style

      supervisors = review.review_user_assignments.select do |rua|
        rua.supervisor? || rua.manager? || rua.responsible?
      end

      document.paragraph(title_style) do |p1|
        p1 << I18n.t('conclusion_review.pat.cover.supervisors')
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        supervisors.each do |supervisor|
          p1 << "#{Prawn::Text::NBSP * 8}• #{supervisor.user.full_name}"
          p1.line_break
        end
      end
    end

    def put_pat_signature_on_rtf document
      supervisors = review.review_user_assignments.select do |rua|
        rua.supervisor? || rua.manager? || rua.responsible?
      end

      add_review_signatures_table_rtf document, supervisors
    end

    def add_review_signatures_table_rtf document, review_user_assignments
      if review_user_assignments.size > 0
        data = []

        review_user_assignments.each do |rua|
          single_data = []

          single_data << rua.user.informal_name
          single_data << rua.user.function

          if organization&.prefix == 'gpat'
            single_data << I18n.t('conclusion_review.pat.cover.organization')
          end

          data << single_data
        end

        table              = document.table(data.count * 4, 1, 2000, 4000)
        table.border_width = 0

        i = 0

        data.each do |single_data|
          table[i][0].line_break
          table[i][0].line_break
          table[i][0].line_break

          single_data.each do |row_data|
            i += 1

            table[i][0] << row_data
          end

          i += 1
        end
      end
    end

    def put_pat_weaknesses_section_on_rtf document
      if pat_has_some_weakness?
        annex_style = style bold: true

        document.page_break

        document.paragraph(@styles['P_ALIGN_RIGTH']) do |p1|
          p1 << I18n.t('conclusion_review.pat.weaknesses.title')
        end

        document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
          p1.apply(annex_style) do |p2|
            p2 << Weakness.model_name.human(count: 0).upcase
            p2.line_break
            p2.line_break
          end
        end

        put_pat_previous_weaknesses_on_rtf  document
        put_pat_weaknesses_on_rtf           document
        put_pat_weaknesses_other_inspections_on_rtf  document
      end
    end

    def put_pat_previous_weaknesses_on_rtf document
      filtered = pat_previous_weaknesses

      if filtered.any?
        previous_title_style = style bold: true

        previous_title = I18n.t(
          'conclusion_review.pat.weaknesses.previous_title',
          prefix: "#{@_next_prefix_rtf}."
        )

        document.paragraph(previous_title_style) do |p1|
          p1 << previous_title
          p1.line_break
        end

        filtered.each do |weakness|
          put_pat_previous_weakness_on_rtf document, weakness, (@_next_index_rtf += 1)
          document.paragraph do |p1|
            p1.line_break
          end
        end

        @_next_prefix_rtf = @_next_prefix_rtf.next
      end
    end

    def put_pat_previous_weakness_on_rtf document, weakness, i
      title_style       = style bold: true
      description_style = style

      document.paragraph(title_style) do |p1|
        p1 << "#{i}. #{weakness.title}"
        p1.line_break
      end

      document.paragraph(description_style) do |p1|
        p1 << weakness.description
      end

      document.paragraph(title_style) do |p1|
        p1.line_break
        p1 << I18n.t('conclusion_review.pat.rtf.weaknesses.risk')
      end

      document.paragraph(description_style) do |p1|
        p1 << weakness.risk_text
      end

      if weakness.current_situation.present?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.current_situation')
        end

        document.paragraph(description_style) do |p1|
          p1 << weakness.current_situation
        end
      end

      if weakness.implemented_audited? || weakness.failure?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.follow_up_date')
        end

        document.paragraph(description_style) do |p1|
          p1 << I18n.t("conclusion_review.pat.weaknesses.follow_up_date_#{Finding::STATUS.key(weakness.state)}")
        end
      elsif weakness.follow_up_date
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.follow_up_date')
        end

        document.paragraph(description_style) do |p1|
          p1 << I18n.l(weakness.follow_up_date, format: :minimal)
        end
      end
    end

    def put_pat_weaknesses_on_rtf document
      title_style = style bold: true
      filtered    = pat_weaknesses

      if filtered.any?
        i18n_key_suffix = review.plan_item.cycle? ? 'cycle' : 'sustantive'

        document.paragraph(title_style) do |p1|
          p1 << I18n.t("conclusion_review.pat.weaknesses.current_title.#{i18n_key_suffix}",
                       prefix: "#{@_next_prefix_rtf}.",
                       year: review.period.name)
          p1.line_break
          p1.line_break
        end

        filtered.each do |weakness|
          put_pat_weakness_on_rtf document, weakness, (@_next_index_rtf += 1)

          document.paragraph(title_style) do |p1|
            p1.line_break
            p1.line_break
          end
        end

        @_next_prefix_rtf = @_next_prefix_rtf.next
      end
    end

    def put_pat_weakness_on_rtf document, weakness, i
      title_style       = style bold: true
      description_style = style

      document.paragraph(title_style) do |p1|
        p1 << "#{i}. #{weakness.title}"
      end

      document.paragraph(description_style) do |p1|
        p1 << weakness.description
        p1.line_break
      end

      if weakness.image_model
        document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
          p1.image weakness.image_model.image.path
          p1.line_break
        end
      end

      put_pat_issues_on_rtf document, weakness if weakness.issues.any?

      if weakness.effect.present?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.effect')
        end

        document.paragraph(description_style) do |p1|
          p1 << weakness.effect
        end
      end

      if weakness.audit_recommendations.present?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.audit_recommendations')
        end

        document.paragraph(description_style) do |p1|
          p1 << weakness.audit_recommendations
        end
      end

      document.paragraph(title_style) do |p1|
        p1.line_break
        p1 << I18n.t('conclusion_review.pat.rtf.weaknesses.risk')
      end

      document.paragraph(description_style) do |p1|
        p1 << weakness.risk_text
      end

      if weakness.answer.present?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.answer')
        end

        document.paragraph(description_style) do |p1|
          p1 << weakness.answer
        end
      end

      if weakness.implemented_audited? || weakness.failure?
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.follow_up_date')
        end

        document.paragraph(description_style) do |p1|
          p1 << I18n.t("conclusion_review.pat.weaknesses.follow_up_date_#{Finding::STATUS.key(weakness.state)}")
        end
      elsif weakness.follow_up_date
        document.paragraph(title_style) do |p1|
          p1.line_break
          p1 << I18n.t('conclusion_review.pat.weaknesses.follow_up_date')
        end

        document.paragraph(description_style) do |p1|
          p1 << I18n.l(weakness.follow_up_date, format: :minimal)
        end
      end
    end

    def put_pat_issues_on_rtf document, weakness
      title_style       = style bold: true
      description_style = style
      default_currency  = I18n.t 'number.currency.format.unit'

      document.paragraph(title_style) do |p1|
        p1.line_break
        p1 << Issue.model_name.human(count: 0)
      end

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
          issue.operation
        ].reject(&:blank?).join ' | '

        data       = [amount_text, date_text].compact.join ' - '
        space      = Prawn::Text::NBSP
        issue_line = "#{space * 4}• #{space * 2} #{description} (#{data})"

        document.paragraph(description_style) do |p1|
          p1.line_break
          p1 << issue_line
        end
      end
    end

    def put_pat_weaknesses_other_inspections_on_rtf document
      title_style = style bold: true
      filtered    = pat_weaknesses_other_inspections

      if filtered.any?
        document.paragraph(title_style) do |p1|
          p1 << I18n.t('conclusion_review.pat.weaknesses.external',
                       prefix: "#{@_next_prefix_rtf}.",
                       year: review.period.name)

          p1.line_break
          p1.line_break
        end

        filtered.each do |weakness|
          put_pat_weakness_on_rtf document, weakness, (@_next_index_rtf += 1)

          document.paragraph(title_style) do |p1|
            p1.line_break
            p1.line_break
          end
        end

        @_next_prefix_rtf = @_next_prefix_rtf.next
      end
    end
    def put_pat_workflow_on_rtf document
      if review.workflow
        title_style       = style bold: true
        description_style = style

        document.page_break

        document.paragraph(@styles['P_ALIGN_RIGTH']) do |p1|
          p1.apply(title_style) do |p2|
            p2 << I18n.t('conclusion_review.pat.workflow.title')
            p2.line_break
          end
        end

        document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
          p1.apply(description_style) do |p2|
            p2 << I18n.t('conclusion_review.pat.workflow.subtitle')
            p2.line_break
          end
        end

        review.workflow.workflow_items.each_with_index do |wi, i|
          document.paragraph(@styles['P_ALIGN_RIGTH']) do |p1|
            p1 << "#{i.next}. #{wi.task}"
            p1.line_break
            p1.line_break
          end
        end
      end
    end

    def put_pat_annexes_on_rtf document
      if annexes.any?
        title_style       = style bold: true
        description_style = style

        document.page_break

        document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
          p1.apply(title_style) do |p2|
            p2 << Annex.model_name.human(count: 0).upcase
          end
        end

        filtered_annexes = pat_annexes

        filtered_annexes.each_with_index do |annex, idx|
          document.paragraph(title_style) do |p1|
            p1.line_break
            p1.line_break
            p1 << annex.title
          end

          if annex.description.present?
            document.paragraph(description_style) do |p1|
              p1.line_break
              p1 << annex.description
            end
          end

          if annex.image_models.any?
            document.paragraph(description_style) do |p1|
              p1.line_break
            end

            annex.image_models.each do |image_model|
              document.paragraph(@styles['P_ALIGN_CENTER']) do |p1|
                p1.line_break
                p1.image image_model.image.path
              end
            end
          end

          document.page_break if idx < annexes.size - 1
        end
      end
    end
end
