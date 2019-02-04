module OpeningInterviews::PDF
  extend ActiveSupport::Concern

  def to_pdf organization = Current.organization
    pdf = Prawn::Document.create_generic_pdf :portrait

    pdf.add_generic_report_header organization
    pdf.add_title OpeningInterview.model_name.human(count: 1), 18, :center

    pdf.move_down PDF_FONT_SIZE

    put_items_on pdf
    put_signatures_table_on pdf

    pdf.custom_save_as pdf_name, OpeningInterview.table_name, id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, OpeningInterview.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, OpeningInterview.table_name, id
  end

  def pdf_name
    I18n.t 'opening_interviews.pdf.pdf_name',
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
        [I18n.t('opening_interviews.show.auditeds'), responsibles_text, 0, false],
        [I18n.t('opening_interviews.show.auditors'), auditors_text, 0, false],
        [OpeningInterviewUser.model_name.human(count: 0), assistant_text, 0, false],
        [self.class.human_attribute_name('interview_date'), I18n.l(interview_date), 0, false],
        [self.class.human_attribute_name('start_date'), I18n.l(start_date), 0, false],
        [self.class.human_attribute_name('end_date'), I18n.l(end_date), 0, false],
        [self.class.human_attribute_name('objective'), objective, 0, false],
        [self.class.human_attribute_name('program'), program, 0, false],
        [self.class.human_attribute_name('scope'), scope, 0, false],
        [self.class.human_attribute_name('suggestions'), suggestions, 0, false],
        [self.class.human_attribute_name('comments'), comments, 0, false]
      ]
    end

    def responsibles_text
      responsible_users.map(&:full_name).to_sentence
    end

    def auditors_text
      auditor_users.map(&:full_name).to_sentence
    end

    def assistant_text
      assistant_users.map(&:full_name).to_sentence
    end
end
