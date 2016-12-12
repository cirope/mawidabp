module Findings::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :portrait, false

    put_cover_on pdf

    pdf.start_new_page
    pdf.move_down (PDF_FONT_SIZE * 2.5).round

    put_description_items_on pdf
    put_work_paper_data_on pdf

    pdf.custom_save_as pdf_name, self.class.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, self.class.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, self.class.table_name, id
  end

  def pdf_name
    model_name = self.class.model_name.human

    "#{model_name.downcase.gsub(/\s+/, '_')}-#{review_code}.pdf".sanitized_for_filename
  end

  private

    def put_cover_on pdf
      review_code_title = "<b>#{self.class.human_attribute_name :review_code}</b>: #{review_code}"

      pdf.add_review_header organization, review.identification.strip, review.plan_item.project.strip
      pdf.move_down PDF_FONT_SIZE * 3

      pdf.add_title self.class.model_name.human, (PDF_FONT_SIZE * 1.5).round, :center, false
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title review_code_title, PDF_FONT_SIZE, :center, false
    end

    def put_description_items_on pdf
      description_items.each do |args|
        pdf.add_description_item *args
      end

      pdf.move_down (PDF_FONT_SIZE * 2.5).round

      if kind_of? Weakness
        weakness_description_items.each do |args|
          pdf.add_description_item *args
        end
      end

      put_conditional_items_on pdf

      put_user_data_on pdf

      pdf.add_description_item self.class.human_attribute_name('state'), state_text, 0, false
    end

    def put_conditional_items_on pdf
      unless unanswered?
        label = self.class.human_attribute_name 'answer'

        pdf.add_description_item label, answer, 0, false
      end

      if kind_of?(Weakness) && (implemented? || being_implemented?)
        label = Weakness.human_attribute_name 'follow_up_date'
        value = follow_up_date ? I18n.l(follow_up_date, format: :long) : nil

        pdf.add_description_item label, value, 0, false
      end

      if implemented_audited?
        label = self.class.human_attribute_name 'solution_date'
        value = solution_date ? I18n.l(solution_date, format: :long) : nil

        pdf.add_description_item label, value, 0, false
      end

      if origination_date.present?
        label = self.class.human_attribute_name 'origination_date'
        value = I18n.l origination_date, format: :long

        pdf.add_description_item label, value , 0, false
      end
    end

    def put_user_data_on pdf
      audited = users.select { |u| u.can_act_as_audited? }.map &:full_name

      pdf.add_description_item(self.class.human_attribute_name('user_ids'), audited.join('; '), 0, false)
      pdf.add_description_item(self.class.human_attribute_name('audit_comments'), audit_comments, 0, false)
    end

    def put_work_paper_data_on pdf
      work_papers_label = ControlObjectiveItem.human_attribute_name 'work_papers'
      finding_title     = "#{self.class.model_name.human} #{review_code} - #{title}"

      if work_papers.present?
        pdf.start_new_page
        pdf.move_down PDF_FONT_SIZE * 3

        pdf.add_title work_papers_label, (PDF_FONT_SIZE * 1.5).round, :center, false
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title finding_title, (PDF_FONT_SIZE * 1.5).round, :center, false

        pdf.move_down PDF_FONT_SIZE * 3

        work_papers.each do |wp|
          pdf.text wp.inspect, align: :center, font_size: PDF_FONT_SIZE
        end
      else
        pdf.add_footnote I18n.t('finding.without_work_papers')
      end
    end

    def description_items
      [
        [self.class.human_attribute_name('control_objective_item_id'), control_objective_item.to_s, 0, false],
        [self.class.human_attribute_name('review_code'), review_code, 0, false],
        [self.class.human_attribute_name('title'), self.title, 0, false],
        [self.class.human_attribute_name('description'), self.description, 0, false]
      ]
    end

    def weakness_description_items
      [
        [Weakness.human_attribute_name('risk'), risk_text, 0, false],
        [Weakness.human_attribute_name('priority'), priority_text, 0, false],
        [Weakness.human_attribute_name('effect'), effect, 0, false],
        [Weakness.human_attribute_name('audit_recommendations'), audit_recommendations, 0, false]
      ]
    end

end
