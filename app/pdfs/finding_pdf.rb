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

    def add_body
      put_findings @findings.preload(:review, control_objective: {
        process_control: :best_practice
      })

      put_issues if Current.conclusion_pdf_format == 'pat'
    end

    def put_findings findings
      row_data = []

      findings.each { |finding| row_data << row_data_for(finding) }

      put_findings_table row_data
    end

    def row_data_for finding
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

    def put_findings_table row_data
      pdf.move_down PDF_FONT_SIZE

      if row_data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options column_widths

          pdf.table row_data.insert(0, column_headers), table_options do
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

    def column_order
      headers = [
        ['review', Review.model_name.human, 10],
        ['review_code', Finding.human_attribute_name('review_code'), 5],
        (['best_practice', BestPractice.model_name.human, 16] unless Current.conclusion_pdf_format == 'pat'),
        (['process_control', ProcessControl.model_name.human, 19] unless Current.conclusion_pdf_format == 'pat'),
        ['title', Finding.human_attribute_name('title'), 49]
      ].compact

      headers += pat_extra_headers if Current.conclusion_pdf_format == 'pat'
      headers
    end

    def pat_extra_headers
      [
        ['description', Finding.human_attribute_name('description'), 12],
        ['state', Finding.human_attribute_name('state'), 12],
        ['issue', Issue.model_name.human.pluralize, 12]
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

    def put_issues
      row_data = []

      @findings.each do |finding|
        finding.issues.without_close_date.each do |issue|
          row_data << [
            finding.review_code,
            issue.customer,
            issue.entry,
            issue.operation,
            issue.comments,
            issue.currency,
            issue.amount
          ]
        end
      end

      put_issues_table row_data
    end

    def put_issues_table(row_data)
      pdf.move_down PDF_FONT_SIZE

      if row_data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options issue_column_widths

          pdf.table row_data.insert(0, issue_column_headers), table_options do
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

    def issue_column_headers
      [
        "<b>#{Finding.human_attribute_name('review_code')}</b>",
        "<b>#{Issue.human_attribute_name('customer')}</b>",
        "<b>#{Issue.human_attribute_name('entry')}</b>",
        "<b>#{Issue.human_attribute_name('operation')}</b>",
        "<b>#{Issue.human_attribute_name('comments')}</b>",
        "<b>#{Issue.human_attribute_name('currency')}</b>",
        "<b>#{Issue.human_attribute_name('amount')}</b>"
      ]
    end

    def issue_column_widths
      [
        pdf.percent_width(10),
        pdf.percent_width(20),
        pdf.percent_width(20),
        pdf.percent_width(15),
        pdf.percent_width(20),
        pdf.percent_width(5),
        pdf.percent_width(10)
      ]
    end

    def save
      pdf.custom_save_as pdf_name, Finding.table_name, random_id
    end

    def pdf_name
      "#{@title.downcase.gsub(/\s+/, '_')}.pdf".sanitized_for_filename
    end
end
