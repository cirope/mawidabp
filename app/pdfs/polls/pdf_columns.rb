module Polls::PDFColumns
  extend ActiveSupport::Concern

  def columns_order
    columns = { Question.model_name.human => 40 }

    Question::ANSWER_OPTIONS.each do |option|
      columns[I18n.t("activerecord.attributes.answer_option.options.#{option}")] = 12
    end

    columns
  end

  def column_headers
    columns_order.keys
  end

  def column_widths
    columns_order.values.map { |col_with| pdf.percent_width(col_with) }
  end

  def answer_options question, answers
    new_row = [question]

    Question::ANSWER_OPTIONS.each_with_index do |option, i|
      new_row << "#{answers[i]} %"
    end

    new_row
  end
end
