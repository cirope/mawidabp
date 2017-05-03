module Findings::ClassPDF
  extend ActiveSupport::Concern

  module ClassMethods
    def to_pdf
      pdf = Prawn::Document.create_generic_pdf :landscape, false

      pdf.add_generic_report_header current_organization
      pdf.add_title *pdf_title

      put_findings_on pdf, includes(:review, control_objective: {
        process_control: :best_practice
      })

      pdf.custom_save_as pdf_name, table_name, random_id
    end

    def absolute_pdf_path
      Prawn::Document.absolute_path pdf_name, table_name, random_id
    end

    def relative_pdf_path
      Prawn::Document.relative_path pdf_name, table_name, random_id
    end

    def pdf_name
      model_name = I18n.t 'finding.index_title'

      "#{model_name.downcase.gsub(/\s+/, '_')}.pdf".sanitized_for_filename
    end

    private

      def random_id
        Thread.current[:finding_random_id] ||= rand(99_999_999)
      end

      def pdf_title
        [model_name.human(count: 0), (PDF_FONT_SIZE * 1.5).round, :center, false]
      end

      def pdf_column_order
        [
          ['review', Review.model_name.human, 10],
          ['review_code', human_attribute_name('code'), 5],
          ['best_practice', BestPractice.model_name.human, 16],
          ['process_control', ProcessControl.model_name.human, 19],
          ['title', human_attribute_name('title'), 49]
        ]
      end

      def pdf_column_headers
        pdf_column_order.map { |name, label, with| "<b>#{label}</b>" }
      end

      def pdf_column_widths pdf
        pdf_column_order.map { |name, label, width| pdf.percent_width width }
      end

      def put_findings_on pdf, findings
        row_data = []

        findings.each { |finding| row_data << row_data_for(finding) }

        put_findings_table_on pdf, row_data
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

      def put_findings_table_on pdf, row_data
        pdf.move_down PDF_FONT_SIZE

        if row_data.present?
          pdf.font_size (PDF_FONT_SIZE * 0.75).round do
            table_options = pdf.default_table_options pdf_column_widths(pdf)

            pdf.table row_data.insert(0, pdf_column_headers), table_options do
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
  end
end
