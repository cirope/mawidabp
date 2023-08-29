require 'test_helper'

class AnswerMultiChoiceTest < ActiveSupport::TestCase
  setup do
    @answer = answers :answer_multi_choice
  end

  test 'must be incompleted when is blank answer option' do
    @answer.answer_option = nil

    refute @answer.completed?
  end

  test 'must be completed when is present answer option' do
    assert @answer.completed?
  end
end
