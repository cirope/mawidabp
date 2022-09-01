module ConclusionReviews::CroPdf
  extend ActiveSupport::Concern

  CUSTOM_LABELS = {
    origination_date:      I18n.t('conclusion_review.cro.findings.origination_date'),
    risk:                  I18n.t('conclusion_review.cro.weakness.risk'),
    effect:                I18n.t('conclusion_review.cro.weakness.effect'),
    audit_recommendations: I18n.t('conclusion_review.cro.weakness.audit_recommendations'),
    answer:                I18n.t('conclusion_review.cro.findings.answer'),
    user_ids:              I18n.t('conclusion_review.cro.findings.user_ids'),
    follow_up_date:        I18n.t('conclusion_review.cro.findings.estimated_follow_up_date')
  }

  def cro_pdf organization = nil, *args
    options = args.extract_options!
    pdf     = Prawn::Document.create_generic_pdf :portrait,
                footer:     false,
                hide_brand: true,
                margins:    [35, 20, 20, 25]

    put_default_watermark_on pdf
    put_cro_header_on        pdf, organization
    put_cro_cover_on         pdf, organization
    put_cro_index_on         pdf
    put_cro_sections_on      pdf, options

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, id
  end

  private

    def put_cro_header_on pdf, organization
      put_first_page_header  pdf, organization
      put_other_pages_header pdf, organization

      pdf.add_page_footer font_size = 10, skip_first_page = true
    end

    def put_cro_cover_on pdf, organization
      date = I18n.l(issue_date, format: :long).strip
      name = organization.name.upcase

      pdf.text I18n.t('conclusion_review.cro.cover.date', date: date),
        align: :right

      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t('conclusion_review.cro.cover.to_html', organization: name),
        inline_format: true

      pdf.move_down PDF_FONT_SIZE * 4

      pdf.text I18n.t(
        'conclusion_review.cro.cover.reference',
        business_unit: review.business_unit.name.upcase,
        business_unit_type: review.business_unit_type.name.upcase
      ), align: :right, style: :bold

      pdf.move_down PDF_FONT_SIZE * 4

      pdf.text I18n.t('conclusion_review.cro.cover.text'), align: :justify

      put_cro_sign_on pdf
    end

    def put_cro_index_on pdf
      pdf.start_new_page

      pdf.add_title I18n.t('conclusion_review.cro.index.title'),
        PDF_FONT_SIZE * 1.5, :center, true

      pdf.move_down PDF_FONT_SIZE * 3

      %w(
        objective
        applied_procedures
        findings
        follow_up
        conclusion
      ).each do |section|
        text = I18n.t(
          "conclusion_review.cro.section.#{section}",
          space: Prawn::Text::NBSP
        )

        pdf.text "<link anchor=\"#{section}\">#{text}</link>", style: :bold,
          size: PDF_FONT_SIZE * 1.25, inline_format: true

        pdf.move_down PDF_FONT_SIZE * 0.25
      end
    end

    def put_cro_sections_on pdf, options
      pdf.start_new_page

      put_cro_objective_section_on          pdf
      put_cro_applied_procedures_section_on pdf, options
      put_cro_findings_section_on           pdf
      put_cro_follow_up_section_on          pdf
      put_cro_conclusion_section_on         pdf
    end

    def put_cro_objective_section_on pdf
      put_cro_section_dest_on pdf, 'objective'

      text = I18n.t(
        'conclusion_review.cro.objective.text',
        business_unit: review.business_unit.name
      )

      pdf.move_down PDF_FONT_SIZE
      pdf.text text, align: :justify
    end

    def put_cro_applied_procedures_section_on pdf, options
      grouped_objectives = grouped_control_objectives({})

      pdf.move_down PDF_FONT_SIZE
      put_cro_section_dest_on pdf, 'applied_procedures'
      pdf.move_down PDF_FONT_SIZE

      put_default_control_objectives_on pdf, grouped_objectives, options
    end

    def put_cro_findings_section_on pdf
      grouped_objectives  = grouped_control_objectives({})
      use_finals          = kind_of? ConclusionFinalReview
      review_has_findings = grouped_objectives.any? do |_, cois|
        has_findings_for_review? cois, :weaknesses, use_finals
      end

      pdf.move_down PDF_FONT_SIZE
      put_cro_section_dest_on pdf, 'findings'

      if review_has_findings
        put_cro_default_control_objective_findings_on pdf, grouped_objectives,
          :weaknesses, use_finals
      else
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.cro.findings.empty'),
          size: PDF_FONT_SIZE
      end
    end

    def put_cro_follow_up_section_on pdf
      pdf.move_down PDF_FONT_SIZE
      put_cro_section_dest_on pdf, 'follow_up'

      if review.finding_review_assignments.any?
        hide = %w(audit_comments title review_code state repeated tasks_data)
        show = %w(current_situation)

        review.finding_review_assignments.map do |fra|
          finding = fra.finding
          coi     = finding.control_objective_item

          pdf.move_down PDF_FONT_SIZE
          pdf.text coi.finding_pdf_data(
            finding, show: show, hide: hide, custom_labels: CUSTOM_LABELS
          ), align: :justify, inline_format: true

          if finding.repeated_in
            pdf.text coi.put_cro_new_observations(
              finding.repeated_in
            ), align: :justify, inline_format: true
          end
        end
      else
        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.cro.follow_up.empty'),
          size: PDF_FONT_SIZE
      end
    end

    def put_cro_conclusion_section_on pdf
      pdf.move_down PDF_FONT_SIZE
      put_cro_section_dest_on pdf, 'conclusion'

      if conclusion.present?
        pdf.text conclusion, align: :justify, inline_format: true
      end
    end

    def put_cro_section_dest_on pdf, section
      text = I18n.t(
        "conclusion_review.cro.section.#{section}", space: Prawn::Text::NBSP
      )

      pdf.add_dest section, pdf.dest_xyz(pdf.bounds.absolute_left, pdf.y)
      pdf.add_title text, PDF_FONT_SIZE * 1.25
    end

    def put_cro_sign_on pdf
      width       = pdf.bounds.width / 2.5
      coordinates = [pdf.bounds.right - width, pdf.y - PDF_FONT_SIZE.pt * 14]

      pdf.bounding_box coordinates, width: width do
        pdf.put_hr
        pdf.text I18n.t('conclusion_review.cro.cover.sign'), align: :center,
          style: :bold
      end
    end

    def put_first_page_header pdf, organization
      y_pointer = pdf.y
      font_size = PDF_HEADER_FONT_SIZE

      pdf.add_organization_image organization, font_size * 2.25

      pdf.canvas do
        label       = I18n.t 'conclusion_review.cro.header.legend_html'
        coordinates = [
          pdf.bounds.width / 2.0,
          pdf.bounds.top - font_size.pt * 1.5
        ]

        pdf.text_box label, at: coordinates, size: font_size * 0.65,
          align: :right, inline_format: true,
          width: (coordinates[0] - pdf.page.margins[:right])
      end

      pdf.bounding_box [0, y_pointer - PDF_HEADER_FONT_SIZE * 3], width: pdf.bounds.width do
        pdf.put_hr
      end

      pdf.y = y_pointer
    end

    def put_other_pages_header pdf, organization
      y_pointer = pdf.y

      pdf.repeat ->(page) { page > 1 } do
        pdf.add_organization_image organization, PDF_HEADER_FONT_SIZE * 2.25
        pdf.add_organization_co_brand_image organization, PDF_HEADER_FONT_SIZE * 2.25

        pdf.bounding_box [0, y_pointer - PDF_HEADER_FONT_SIZE], width: pdf.bounds.width do
          pdf.put_hr
        end
      end

      pdf.y = y_pointer
    end

    def put_cro_default_control_objective_findings_on pdf, grouped_control_objectives, type, use_finals
      grouped_control_objectives.each do |process_control, cois|
        has_findings = has_findings_for_review? cois, type, use_finals

        if has_findings
          hide = %w(audit_comments title review_code state repeated origination_date tasks_data)

          cois.sort.each do |coi|
            coi_findings = coi_findings_for coi, type, use_finals

            if coi_findings.not_revoked.present?
              findings = coi_findings.not_revoked.sort_for_review

              findings.each do |f|
                pdf.move_down PDF_FONT_SIZE
                pdf.text coi.finding_pdf_data(
                  f, hide: hide, custom_labels: CUSTOM_LABELS
                ), align: :justify, inline_format: true
              end
            end
          end
        end
      end
    end
end
