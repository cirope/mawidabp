module Reviews::Pdf
  extend ActiveSupport::Concern

  def to_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :landscape, margins: [25, 5, 20, 5]

    pdf.add_generic_report_header organization
    pdf.add_title *pdf_title
    pdf.move_down PDF_FONT_SIZE

    put_description pdf
    put_control_objective_items_table_on pdf

    if Current.conclusion_pdf_format == 'nbc'
      external_reviews.map(&:alternative_review).each do |alt_review|
        pdf.start_new_page
        alt_review.put_description pdf
        alt_review.put_control_objective_items_table_on pdf
      end
    end

    pdf.custom_save_as pdf_name, Review.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, Review.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, Review.table_name, id
  end

  def pdf_name
    I18n.t 'review.pdf.pdf_name',
      identification: identification.sanitized_for_filename
  end

  protected

    def put_description pdf
      pdf.add_description_item Review.human_attribute_name('identification'),
        identification, 0, false, PDF_FONT_SIZE
      pdf.add_description_item Review.human_attribute_name('plan_item'),
        plan_item.project, 0, false, PDF_FONT_SIZE

      pdf.move_down PDF_FONT_SIZE
    end

    def put_control_objective_items_table_on pdf
      pdf.font_size (PDF_FONT_SIZE * 0.5).round do
        table_options = pdf.default_table_options pdf_widths(pdf)

        pdf.table pdf_rows.insert(0, pdf_headers), table_options do
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

  private

    def pdf_title
      [
        [Review.model_name.human, identification].join(' '),
        (PDF_FONT_SIZE * 1.5).round,
        :center
      ]
    end

    def pdf_columns
      tests_width = if HIDE_CONTROL_EFFECTS && HIDE_CONTROL_COMPLIANCE_TESTS
                      35
                    elsif HIDE_CONTROL_EFFECTS
                      25
                    elsif HIDE_CONTROL_COMPLIANCE_TESTS
                      30
                    else
                      20
                    end

      [
        [ProcessControl.model_name.human, 6],
        [ControlObjective.model_name.human, 6],
        ([Control.human_attribute_name('effects'), 10] unless HIDE_CONTROL_EFFECTS),
        [Control.human_attribute_name('control'), 10],
        [Control.human_attribute_name('design_tests'), tests_width],
        ([Control.human_attribute_name('compliance_tests'), 20] unless HIDE_CONTROL_COMPLIANCE_TESTS),
        [Control.human_attribute_name('sustantive_tests'), tests_width],
        [ControlObjectiveItem.human_attribute_name('auditor_comment'), 8]
      ].compact
    end

    def pdf_headers
      pdf_columns.map { |col_name, _col_with| col_name }
    end

    def pdf_widths pdf
      pdf_columns.map { |_col_name, col_with| pdf.percent_width(col_with) }
    end

    def pdf_rows
      rows = []

      grouped_control_objective_items.each do |pc, cois|
        cois.sort.each do |coi|
          rows << [
            coi.process_control.name,
            coi.control_objective_text.to_s,
            (coi.control.effects.to_s unless HIDE_CONTROL_EFFECTS),
            coi.control.control.to_s,
            coi.control.design_tests.to_s,
            (coi.control.compliance_tests.to_s unless HIDE_CONTROL_COMPLIANCE_TESTS),
            coi.control.sustantive_tests.to_s,
            coi.auditor_comment.to_s
          ].compact
        end
      end

      rows
    end
end
