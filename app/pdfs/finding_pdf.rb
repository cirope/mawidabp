class FindingPdf < Prawn::Document
  attr_reader :pdf

  def initialize title:, columns:, query:, findings:, current_organization:
    @current_organization               = current_organization
    @title, @columns, @query, @findings = title, columns, query, findings

    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, Finding.table_name, random_id
  end

  def self.create attributes = nil
    _pdf = new **Hash(attributes)
    path = _pdf.send :generate

    FileRemoveJob.set(wait: 30.minutes).perform_later path

    _pdf
  end

  private

    def random_id
      @random_id ||= rand 99_999_999
    end

    def generate
      add_header
      add_body
      add_filter_text
      save
    end

    def add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title @title
    end

    def add_body
      preloaded_findings = preload_findings_data

      findings_data = generate_table_data preloaded_findings
      put_table findings_data, column_headers, column_widths

      if Current.conclusion_pdf_format == 'pat'
        issues_data = generate_table_data preloaded_findings, format: :issues
        put_table issues_data, issue_column_headers, issue_column_widths
      end
    end

    def preload_findings_data
      if Current.conclusion_pdf_format == 'pat'
        @findings.preload :review
      else
        @findings.preload :review, control_objective: { process_control: :best_practice }
      end
    end

    def generate_table_data findings, format: :finding
      row_data = []

      findings.each do |finding|
        if format == :finding
          row_data << finding_row_data_for(finding)
        elsif format == :issues
          finding.issues.without_close_date.each do |issue|
            row_data << issue_row_data_for(issue, finding.review_code)
          end
        end
      end

      row_data
    end

    def finding_row_data_for finding
      rows = [
        finding.review.identification,
        finding.review_code,
        ((finding.control_objective&.process_control&.best_practice&.name || '') unless Current.conclusion_pdf_format == 'pat'),
        (finding.control_objective&.process_control&.name unless Current.conclusion_pdf_format == 'pat'),
        finding.title
      ].compact

      rows += pat_extra_rows(finding) if Current.conclusion_pdf_format == 'pat'
      rows
    end

    def pat_extra_rows finding
      [
        finding.description,
        finding.state_text,
        show_pdf_issues(finding) ? I18n.t('findings.pdf.issue', review_code: finding.review_code) : ''
      ]
    end

    def show_pdf_issues finding
      finding.issues.any? && finding.issues.without_close_date.count > 0
    end

    def issue_row_data_for issue, review_code 
      [
        review_code,
        issue.customer,
        issue.entry,
        issue.operation,
        issue.comments,
        issue.currency,
        issue.amount
      ]
    end

    def put_table data, headers, column_widths
      pdf.move_down PDF_FONT_SIZE

      if data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options column_widths

          pdf.table data.insert(0, headers), table_options do
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

    def add_filter_text
      if @columns.present? || @query.present?
        query   = @query.flatten.map { |q| "<b>#{q}</b>" }
        columns = @columns.map do |c|
          f = filter_columns[c]

          f && "<b>#{f}</b>"
        end.compact

        text = I18n.t 'finding.pdf.filtered_by',
          query:   query.to_sentence,
          columns: columns.to_sentence,
          count:   columns.size

        pdf.move_down PDF_FONT_SIZE
        pdf.text text, font_size: (PDF_FONT_SIZE * 0.75).round, inline_format: true
      end
    end

    def column_order
      headers = [
        ['review', Review.model_name.human, 10],
        ['review_code', Finding.human_attribute_name('review_code'), 5],
        (['best_practice', BestPractice.model_name.human, 16] unless Current.conclusion_pdf_format == 'pat'),
        (['process_control', ProcessControl.model_name.human, 20] unless Current.conclusion_pdf_format == 'pat'),
        ['title', Finding.human_attribute_name('title'), 49]
      ].compact

      headers += pat_extra_headers if Current.conclusion_pdf_format == 'pat'
      headers
    end

    def pat_extra_headers
      [
        ['description', Finding.human_attribute_name('description'), 13],
        ['state', Finding.human_attribute_name('state'), 10],
        ['issue', Issue.model_name.human.pluralize, 13]
      ]
    end

    def column_headers
      column_order.map { |name, label, with| "<b>#{label}</b>" }
    end

    def column_widths
      column_order.map { |name, label, width| pdf.percent_width width }
    end

    def filter_columns
      {
        'organization' => Finding.human_attribute_name('organization'),
        'review'       => Review.model_name.human,
        'project'      => PlanItem.human_attribute_name('project'),
        'review_code'  => Finding.human_attribute_name('review_code'),
        'title'        => Finding.human_attribute_name('title'),
        'updated_at'   => Finding.human_attribute_name('updated_at'),
        'tags'         => Tag.model_name.human(count: 0)
      }
    end

    def issue_column_order
      [
        ['review_code', Finding.human_attribute_name('review_code'), 5],
        ['customer', Issue.human_attribute_name('customer'), 20],
        ['entry', Issue.human_attribute_name('entry'), 20],
        ['operation', Issue.human_attribute_name('operation'), 20],
        ['comments', Issue.human_attribute_name('comments'), 20],
        ['currency', Issue.human_attribute_name('currency'), 5],
        ['amount', Issue.human_attribute_name('amount'), 10]
      ]
    end

    def issue_column_headers
      issue_column_order.map { |_, label, _| "<b>#{label}</b>" }
    end

    def issue_column_widths
      issue_column_order.map { |_, _, width| pdf.percent_width(width) }
    end

    def save
      pdf.custom_save_as pdf_name, Finding.table_name, random_id
    end

    def pdf_name
      "#{@title.downcase.gsub(/\s+/, '_')}.pdf".sanitized_for_filename
    end
end
