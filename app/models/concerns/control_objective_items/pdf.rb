module ControlObjectiveItems::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :portrait, false

    put_header_on pdf, organization

    pdf.move_down (PDF_FONT_SIZE * 2.5).round

    put_description_items_on pdf
    put_work_paper_data_on   pdf

    pdf.custom_save_as pdf_name, self.class.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, self.class.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, self.class.table_name, id
  end

  def pdf_name
    "#{self.class.model_name.human.downcase.gsub(/\s/, '_')}-#{'%08d' % id}.pdf"
  end

  private

    def put_header_on pdf, organization
      process_control_label   = ProcessControl.model_name.human
      control_objective_label = self.class.model_name.human
      options                 = [0, false, (PDF_FONT_SIZE * 1.25).round]

      pdf.add_review_header organization,
        review.identification,
        review.plan_item.project

      pdf.move_down (PDF_FONT_SIZE * 2.5).round

      pdf.add_description_item process_control_label, process_control&.name,
        *options
      pdf.add_description_item control_objective_label, to_s, *options
    end

    def put_description_items_on pdf
      description_items.each do |args|
        pdf.add_description_item *args
      end
    end

    def put_work_paper_data_on pdf
      work_papers_title = WorkPaper.model_name.human count: 0

      if work_papers.any?
        pdf.start_new_page

        pdf.move_down PDF_FONT_SIZE * 3
        pdf.add_title work_papers_title, (PDF_FONT_SIZE * 1.5).round, :center, false
        pdf.move_down PDF_FONT_SIZE * 3

        work_papers.each do |wp|
          pdf.text wp.inspect, align: :center, font_size: PDF_FONT_SIZE
        end
      else
        pdf.add_footnote I18n.t('control_objective_item.without_work_papers')
      end
    end

    def description_items
      [
        [self.class.human_attribute_name('relevance'), relevance_text(show_value: true), 0, false],
        [self.class.human_attribute_name('audit_date'), (I18n.l(audit_date, format: :long) if audit_date), 0, false],
        ([Control.human_attribute_name('effects'), control.effects, 0, false] unless HIDE_CONTROL_EFFECTS),
        [Control.human_attribute_name('control'), control.control, 0, false],
        [self.class.human_attribute_name('design_score'), design_score_text(show_value: true), 0, false],
        [Control.human_attribute_name('design_tests'), control.design_tests, 0, false],
        ([self.class.human_attribute_name('compliance_score'), compliance_score_text(show_value: true), 0, false] unless HIDE_CONTROL_COMPLIANCE_TESTS),
        ([Control.human_attribute_name('compliance_tests'), control.compliance_tests, 0, false] unless HIDE_CONTROL_COMPLIANCE_TESTS),
        [self.class.human_attribute_name('sustantive_score'), sustantive_score_text(show_value: true), 0, false],
        [Control.human_attribute_name('sustantive_tests'), control.sustantive_tests, 0, false],
        [self.class.human_attribute_name('auditor_comment'), auditor_comment, 0, false],
        [self.class.human_attribute_name('effectiveness'), "#{effectiveness}%", 0, false]
      ].compact
    end
end
