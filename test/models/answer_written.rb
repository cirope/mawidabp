require 'test_helper'

class AnswerWrittenTest < ActiveSupport::TestCase
  setup do
    @answer = answers :answer_written
  end

  test 'invalid because length of answer' do
    @answer.answer = 'abcde' * 52

    assert @answer.invalid?
    assert_error @answer, :answer, :too_long, count: 255
  end

  test 'must be incompleted when is blank answer option' do
    @answer.answer = nil

    refute @answer.completed?

    @answer.answer = ''

    refute @answer.completed?
  end

  test 'must be completed when is present answer option' do
    assert @answer.completed?
  end
end
