module ConclusionReviews::WorkflowPdf
  extend ActiveSupport::Concern

  def create_workflow_pdf organization = nil
    pdf        = Prawn::Document.create_generic_pdf :portrait, false
    use_finals = kind_of? ConclusionFinalReview

    pdf.add_watermark I18n.t('pdf.draft') unless use_finals

    pdf.add_review_header organization || self.organization,
      review&.identification,
      review&.plan_item&.project

    pdf.move_down (PDF_FONT_SIZE * 1.5).round

    pdf.add_title I18n.t('conclusion_review.workflow.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    put_control_objective_workflow_on pdf, use_finals

    pdf.custom_save_as workflow_pdf_name, ConclusionReview.table_name, id
  end

  def absolute_workflow_pdf_path
    Prawn::Document.absolute_path workflow_pdf_name, ConclusionReview.table_name, id
  end

  def relative_workflow_pdf_path
    Prawn::Document.relative_path workflow_pdf_name, ConclusionReview.table_name, id
  end

  def workflow_pdf_name
    I18n.t 'conclusion_review.workflow.pdf_name'
  end

  private

    def put_control_objective_workflow_on pdf, use_finals
      pdf.move_down (PDF_FONT_SIZE * 1.5).round

      grouped_control_objectives = control_objective_items.group_by &:process_control

      grouped_control_objectives.each do |process_control, cois|
        pdf.move_down PDF_FONT_SIZE
        pdf.add_description_item "#{ProcessControl.model_name.human}", process_control.name, 0, false

        put_workflow_control_objectives_on pdf, cois, use_finals
      end
    end

    def put_workflow_control_objectives_on pdf, cois, use_finals
      cois.sort.each do |coi|
        pdf.move_down PDF_FONT_SIZE
        pdf.add_description_item "• #{ControlObjectiveItem.model_name.human}", coi.to_s, PDF_FONT_SIZE * 2, false

        put_workflow_work_papers_on pdf, coi,
          title: I18n.t('conclusion_review.workflow.control_objective_work_papers')

        put_workflow_findings_on pdf, coi, :weaknesses, use_finals
        put_workflow_findings_on pdf, coi, :oportunities, use_finals
      end
    end

    def put_workflow_work_papers_on pdf, model, title:, indent_factor: 4
      if model.work_papers.any?
        pdf.move_down PDF_FONT_SIZE
        pdf.text "• <b>#{title}</b>:",
          indent_paragraphs: PDF_FONT_SIZE * indent_factor,
          inline_format: true

        model.work_papers.each do |wp|
          pdf.text wp.inspect,
            indent_paragraphs: PDF_FONT_SIZE * (indent_factor + 2),
            inline_format: true
        end
      end
    end

    def put_workflow_findings_on pdf, coi, type, use_finals
      findings = use_finals ? coi.send(:"final_#{type}") : coi.send(type)

      if findings.any?
        title = I18n.t "conclusion_review.workflow.control_objective_#{type}"

        pdf.move_down PDF_FONT_SIZE
        pdf.text "<b>#{title}</b>:", indent_paragraphs: PDF_FONT_SIZE * 4,
          inline_format: true

        findings.each do |f|
          attributes = if f.kind_of? Weakness
                         [f.review_code, f.title, f.risk_text, f.state_text]
                       else
                         [f.review_code, f.title, f.state_text]
                       end

          pdf.text attributes.join(' - '), indent_paragraphs: PDF_FONT_SIZE * 6

          put_workflow_work_papers_on pdf, f, indent_factor: 8,
            title: I18n.t('conclusion_review.workflow.finding_work_papers')
        end
      end
    end
end
