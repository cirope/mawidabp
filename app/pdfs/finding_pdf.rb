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
    _pdf = new attributes
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
      put_findings @findings.includes(:review, control_objective: {
        process_control: :best_practice
      })
    end

    def put_findings findings
      row_data = []

      findings.each { |finding| row_data << row_data_for(finding) }

      put_findings_table row_data
    end

    def row_data_for finding
      [
        finding.review.identification,
        finding.review_code,
        finding.control_objective&.process_control&.best_practice&.name || '',
        finding.control_objective&.process_control&.name,
        finding.title
      ]
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
      [
        ['review', Review.model_name.human, 10],
        ['review_code', Finding.human_attribute_name('code'), 5],
        ['best_practice', BestPractice.model_name.human, 16],
        ['process_control', ProcessControl.model_name.human, 19],
        ['title', Finding.human_attribute_name('title'), 49]
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
        'review_code'  => Finding.human_attribute_name('code'),
        'title'        => Finding.human_attribute_name('title'),
        'tags'         => Tag.model_name.human(count: 0)
      }
    end

    def save
      pdf.custom_save_as pdf_name, Finding.table_name, random_id
    end

    def pdf_name
      "#{@title.downcase.gsub(/\s+/, '_')}.pdf".sanitized_for_filename
    end
end
