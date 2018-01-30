module Reviews::ScoreDetails
  extend ActiveSupport::Concern

  def put_score_details_table pdf
    column_data = score_details_column_data

    if column_data.present?
      widths        = score_details_column_widths pdf
      data          = [column_data].insert 0, score_details_column_headers
      table_options = pdf.default_table_options widths

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data, table_options do
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

  private

    def score_details_column_headers
      review_score = score_array.first

      sorted_scores.each_with_index.map do |score, i|
        column_text = I18n.t "score_types.#{score[0]}"

        if score[0] == review_score
          "<b>#{column_text.upcase} (#{self.score}%)</b>"
        else
          column_text
        end
      end
    end

    def score_details_column_widths pdf
      sorted_scores.each_with_index.map do |score, i|
        pdf.percent_width 100.0 / sorted_scores.size
      end
    end

    def score_details_column_data
      sorted_scores.each_with_index.map do |score, i|
        min_percentage = score[1]
        max_percentage = i > 0 && sorted_scores[i - 1] ? sorted_scores[i - 1][1] - 1 : 100

        "#{max_percentage}% - #{min_percentage}%"
      end
    end
end
