module Polls::PDFColumns
  extend ActiveSupport::Concern

  def multi_choice_columns_order
    columns = { Question.model_name.human => 40 }

    Question::ANSWER_OPTIONS.each do |option|
      columns[I18n.t("answer_options.#{option}")] = 10
    end

    columns
  end

  def multi_choice_column_headers
    multi_choice_columns_order.keys
  end

  def multi_choice_column_widths
    multi_choice_columns_order.values.map { |col_with| pdf.percent_width(col_with) }
  end

  def multi_choice_answer_options question, answers
    new_row = [question]

    Question::ANSWER_OPTIONS.each_with_index do |option, i|
      new_row << "#{answers[i]} %"
    end

    new_row
  end

  def yes_no_columns_order
    columns = { Question.model_name.human => 40 }

    Question::ANSWER_YES_NO_OPTIONS.each do |option|
      columns[I18n.t("answer_options.#{option}")] = 20
    end

    columns
  end

  def yes_no_column_headers
    yes_no_columns_order.keys
  end

  def yes_no_column_widths
    yes_no_columns_order.values.map { |col_with| pdf.percent_width(col_with) }
  end

  def yes_no_answer_options question, answers
    new_row = [question]

    Question::ANSWER_YES_NO_OPTIONS.each_with_index do |option, i|
      new_row << "#{answers[i]} %"
    end

    new_row
  end

  def written_columns_order
    {
      Question.model_name.human => 40,
      Poll.human_attribute_name('answered') => 60
    }
  end

  def written_column_headers
    written_columns_order.keys
  end

  def written_column_widths
    written_columns_order.values.map { |col_with| pdf.percent_width(col_with) }
  end

  def written_answer_options question, answers
    [
      question,
      "#{answers.first} %"
    ]
  end
end
