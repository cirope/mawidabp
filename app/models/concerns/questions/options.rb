module Questions::Options
  extend ActiveSupport::Concern

  def options
    if answer_multi_choice?
      Question::ANSWER_OPTIONS
    elsif answer_yes_no?
      Question::ANSWER_YES_NO_OPTIONS
    else
      []
    end
  end

  def option_values
    if answer_multi_choice?
      Question::ANSWER_OPTION_VALUES
    elsif answer_yes_no?
      Question::ANSWER_YES_NO_OPTION_VALUES
    else
      []
    end
  end
end
