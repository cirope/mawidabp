require 'test_helper'

class AnswerYesNoTest < ActiveSupport::TestCase
  setup do
    @answer = answers :answer_yes_no
  end

  test 'must be incompleted when is blank answer option' do
    refute @answer.completed?
  end

  test 'must be completed when is present answer option' do
    @answer.answer_option = answer_options :yes_no_no

    assert @answer.completed?
  end
end
