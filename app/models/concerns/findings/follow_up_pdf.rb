module Findings::FollowUpPDF
  extend ActiveSupport::Concern

  def follow_up_pdf organization = nil
    pdf = Prawn::Document.create_generic_pdf :portrait

    put_follow_up_cover_on             pdf, organization
    put_follow_up_description_items_on pdf
    put_follow_up_user_data_on         pdf
    put_relation_information_on        pdf
    put_history_on                     pdf
    put_follow_up_comments_on          pdf
    put_follow_up_work_papers_on       pdf
    put_follow_up_finding_answers_on   pdf

    pdf.custom_save_as follow_up_pdf_name, Finding.table_name, id
  end

  def absolute_follow_up_pdf_path
    Prawn::Document.absolute_path follow_up_pdf_name, Finding.table_name, id
  end

  def relative_follow_up_pdf_path
    Prawn::Document.relative_path follow_up_pdf_name, Finding.table_name, id
  end

  def follow_up_pdf_name
    code = review_code.sanitized_for_filename

    I18n.t 'finding.follow_up_report.pdf_name', code: code
  end

  private

    def put_follow_up_cover_on pdf, organization
      class_name  = self.class.name.downcase
      line_height = (PDF_FONT_SIZE * 1.25).round

      pdf.add_generic_report_header organization

      pdf.add_title I18n.t("finding.follow_up_report.#{class_name}.title"), line_height, :center
      pdf.move_down line_height

      pdf.add_title I18n.t("finding.follow_up_report.#{class_name}.subtitle"), line_height, :left
      pdf.move_down line_height
    end

    def put_follow_up_description_items_on pdf
      follow_up_description_items.each do |args|
        pdf.add_description_item *args
      end

      if kind_of? Weakness
        weakness_follow_up_description_items.each do |args|
          pdf.add_description_item *args
        end
      end

      pdf.add_description_item Finding.human_attribute_name(:answer), answer, 0, false

      put_follow_up_conditional_items_on pdf

      pdf.add_description_item Finding.human_attribute_name(:audit_comments), audit_comments, 0, false
    end

    def put_follow_up_conditional_items_on pdf
      if kind_of?(Weakness) && follow_up_date
        pdf.add_description_item Finding.human_attribute_name(:follow_up_date), I18n.l(follow_up_date, format: :long), 0, false
      end

      if solution_date
        pdf.add_description_item Finding.human_attribute_name(:solution_date), I18n.l(solution_date, format: :long), 0, false
      end
    end

    def put_follow_up_user_data_on pdf
      audited, auditors = *users.partition(&:can_act_as_audited?)

      pdf.add_title I18n.t('finding.auditors', count: auditors.size), PDF_FONT_SIZE, :left
      pdf.add_list auditors.map(&:full_name), PDF_FONT_SIZE * 2

      pdf.add_title I18n.t('finding.responsibles', count: audited.size), PDF_FONT_SIZE, :left
      pdf.add_list audited.map(&:full_name), PDF_FONT_SIZE * 2
    end

    def put_relation_information_on pdf
      if repeated_ancestors.any?
        pdf.add_title I18n.t('finding.repeated_ancestors'), PDF_FONT_SIZE, :left
        pdf.add_list repeated_ancestors, PDF_FONT_SIZE * 2
      end

      if repeated_children.any?
        pdf.add_title I18n.t('finding.repeated_children'), PDF_FONT_SIZE, :left
        pdf.add_list repeated_children, PDF_FONT_SIZE * 2
      end
    end

    def put_history_on pdf
      important_versions = important_changed_versions

      pdf.add_title I18n.t('finding.change_history'), (PDF_FONT_SIZE * 1.25).round

      if important_versions.size > 1
        put_history_table_on pdf, important_versions
      else
        pdf.text "\n#{I18n.t 'finding.follow_up_report.without_important_changes'}", font_size: PDF_FONT_SIZE
      end
    end

    def put_follow_up_comments_on pdf
      if comments.any?
        column_names   = [['comment', 50], ['user_id', 30], ['created_at', 20]]
        column_headers = follow_up_column_headers_for Comment, column_names
        column_widths  = column_widths_for pdf, column_names
        row_data       = comments_row_data

        pdf.move_down PDF_FONT_SIZE

        pdf.add_title I18n.t('finding.comments'), (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE

        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options column_widths

          pdf.table(row_data.insert(0, column_headers), table_options) do
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
    end

    def put_follow_up_work_papers_on pdf
      if work_papers.any?
        column_names = [
          ['name', 20],
          ['code', 20],
          ['number_of_pages', 20],
          ['description', 40]
        ]

        column_headers = follow_up_column_headers_for WorkPaper, column_names
        column_widths  = column_widths_for pdf, column_names
        row_data       = work_papers_row_data

        pdf.move_down PDF_FONT_SIZE

        pdf.add_title I18n.t('finding.follow_up_report.work_papers'), (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE

        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(row_data.insert(0, column_headers), table_options) do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end
    end

    def put_follow_up_finding_answers_on pdf
      if finding_answers.any?
        pdf.move_down PDF_FONT_SIZE

        pdf.add_title I18n.t('finding.follow_up_report.follow_up_comments'),
          (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE

        finding_answers_items.each do |finding_answer_item|
          finding_answer_item.each do |args|
            pdf.add_description_item *(args | [0, false])
          end

          pdf.move_down PDF_FONT_SIZE
        end
      end
    end

    def put_history_table_on pdf, important_versions
      column_names = [['attribute', 30 ], ['old_value', 35], ['new_value', 35]]
      column_headers = history_column_headers_for column_names
      column_widths  = column_widths_for pdf, column_names

      previous_version = important_versions.shift
      previous_finding = previous_version.reify has_one: false

      important_versions.each do |version|
        version_finding = version.reify has_one: false
        row_data        = history_row_data_for version_finding, previous_finding

        if row_data.present?
          put_history_data_for version, version_finding, pdf, column_headers, column_widths, row_data
        end

        previous_finding = version_finding
        previous_version = version
      end
    end

    def put_history_data_for version, version_finding, pdf, column_headers, column_widths, row_data
      created_at_label = PaperTrail::Version.human_attribute_name :created_at
      version_date     = I18n.l(version_finding&.updated_at || version.created_at, format: :long)
      user_id          = version.persisted? ? version.paper_trail_originator : version.whodunnit
      user_name        = user_id ? User.find(user_id)&.full_name : '--'

      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item created_at_label, version_date
      pdf.add_description_item User.model_name.human, user_name

      pdf.move_down PDF_FONT_SIZE

      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options column_widths

        pdf.table(row_data.insert(0, column_headers), table_options) do
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

    def follow_up_description_items
      issue_date  = self.issue_date ?
        I18n.l(self.issue_date, format: :long) :
        I18n.t('finding.without_conclusion_final_review')

      [
        [Review.model_name.human, "#{review.long_identification} (#{issue_date})", 1, false],
        [Finding.human_attribute_name(:review_code), review_code, 0, false],
        [Finding.human_attribute_name(:title), title, 0, false],
        [ProcessControl.model_name.human, control_objective_item.process_control.name, 0, false],
        [Finding.human_attribute_name(:control_objective_item_id), control_objective_item.to_s, 0, false],
        [self.class.human_attribute_name(:description), description, 0, false],
        [self.class.human_attribute_name(:state), state_text, 0, false]
      ]
    end

    def weakness_follow_up_description_items
      [
        [self.class.human_attribute_name(:risk), risk_text, 0, false],
        ([self.class.human_attribute_name(:priority), priority_text, 0, false] unless HIDE_WEAKNESS_PRIORITY),
        ([Finding.human_attribute_name(:effect), effect, 0, false] unless HIDE_WEAKNESS_EFFECT),
        [Finding.human_attribute_name(:audit_recommendations), audit_recommendations, 0, false]
      ].compact
    end

    def follow_up_important_attributes
      if HIDE_WEAKNESS_PRIORITY
        [:state, :risk, :follow_up_date]
      else
        [:state, :risk, :priority, :follow_up_date]
      end
    end

    def important_changed_versions
      previous_version   = versions.first
      important_versions = [PaperTrail::Version.new]

      while previous_version&.event && last_checked_version = previous_version&.next
        has_important_changes = follow_up_important_attributes.any? do |attribute|
          current_value = last_checked_version.reify(has_one: false) ?
            last_checked_version.reify(has_one: false).send(attribute) : nil
          old_value = previous_version.reify(has_one: false) ?
            previous_version.reify(has_one: false).send(attribute) : nil

          current_value != old_value && !(current_value.blank? && old_value.blank?)
        end

        if has_important_changes
          important_versions << last_checked_version
        end

        previous_version = last_checked_version
      end

      important_versions + [current_version]
    end

    def current_version
      object    = paper_trail.object_attrs_for_paper_trail
      use_plain = self.class.connection.adapter_name == 'PostgreSQL'

      PaperTrail::Version.new(
        item:      self,
        object:    use_plain ? object : object.to_json,
        whodunnit: paper_trail.originator
      )
    end

    def column_widths_for pdf, column_names
      column_names.map do |col_name, col_size|
        pdf.percent_width col_size
      end
    end

    def history_column_headers_for column_names
      column_names.map do |col_name, col_size|
        col_name == 'attribute' ? '' : I18n.t("versions.column_#{col_name}")
      end
    end

    def follow_up_column_headers_for model, column_names
      column_names.map do |col_name, col_size|
        model.human_attribute_name col_name
      end
    end

    def history_row_data_for version_finding, previous_finding
      follow_up_important_attributes.map do |attribute|
        text_method          = :"#{attribute}_text"
        previous_method_name = previous_finding.respond_to?(text_method) ? text_method : attribute
        version_method_name  = version_finding.respond_to?(text_method)  ? text_method : attribute

        [
          Finding.human_attribute_name(attribute),
          previous_finding&.send(previous_method_name).to_translated_string,
          version_finding&.send(version_method_name).to_translated_string
        ]
      end
    end

    def comments_row_data
      comments.map do |comment|
        [
          comment.comment,
          comment.user&.full_name,
          I18n.l(comment.created_at, format: :validation)
        ]
      end
    end

    def work_papers_row_data
      work_papers.map do |work_paper|
        [
          work_paper.name,
          work_paper.code,
          work_paper.number_of_pages || '-',
          work_paper.description
        ]
      end
    end

    def finding_answers_items
      finding_answers.map do |finding_answer|
        [
          [
            FindingAnswer.human_attribute_name('user_id'),
            finding_answer.user&.full_name
          ],
          [
            FindingAnswer.human_attribute_name('created_at'),
            I18n.l(finding_answer.created_at, format: :validation)
          ],
          [
            FindingAnswer.human_attribute_name('answer'),
            finding_answer.answer
          ]
        ]
      end
    end
end
