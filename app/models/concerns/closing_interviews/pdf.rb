module ClosingInterviews::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = Current.organization
    pdf = Prawn::Document.create_generic_pdf :portrait

    pdf.add_generic_report_header organization
    pdf.add_title ClosingInterview.model_name.human(count: 1), 18, :center

    pdf.move_down PDF_FONT_SIZE

    put_items_on pdf
    put_signatures_table_on pdf

    pdf.custom_save_as pdf_name, ClosingInterview.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, ClosingInterview.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, ClosingInterview.table_name, id
  end

  def pdf_name
    I18n.t 'closing_interviews.pdf.pdf_name',
      name: review.identification.sanitized_for_filename.downcase
  end

  private

    def put_items_on pdf
      description_items.each do |args|
        pdf.add_description_item *args
      end
    end

    def put_signatures_table_on pdf
      users = review.review_user_assignments.select(&:include_signature)
      users = users.sort_by { |rua| rua.assignment_type }

      pdf.move_down PDF_FONT_SIZE
      pdf.add_review_signatures_table users
    end

    def description_items
      [
        [self.class.human_attribute_name('review'), review.to_s, 0, false],
        [I18n.t('closing_interviews.show.auditeds'), auditeds_text, 0, false],
        [I18n.t('closing_interviews.show.auditors'), auditors_text, 0, false],
        [ClosingInterviewUser.model_name.human(count: 0), users_text, 0, false],
        [self.class.human_attribute_name('interview_date'), I18n.l(interview_date), 0, false],
        [self.class.human_attribute_name('findings_summary'), findings_summary, 0, false],
        [self.class.human_attribute_name('recommendations_summary'), recommendations_summary, 0, false],
        [self.class.human_attribute_name('suggestions'), suggestions, 0, false],
        [self.class.human_attribute_name('comments'), comments, 0, false],
        [self.class.human_attribute_name('audit_comments'), audit_comments, 0, false],
        [self.class.human_attribute_name('responsible_comments'), responsible_comments, 0, false]
      ]
    end

    def auditeds_text
      review.users.select(&:can_act_as_audited?).map(&:full_name).to_sentence
    end

    def auditors_text
      review.users.reject(&:can_act_as_audited?).map(&:full_name).to_sentence
    end

    def users_text
      users.map(&:full_name).to_sentence
    end
end
