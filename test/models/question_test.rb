require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  setup do
    set_organization

    @question = questions :question_multi_choice
  end

  test 'create' do
    assert_difference 'Question.count' do
      Question.create(
        :question => '¿Cual es su edad?',
        :sort_order => 1,
        :answer_type => 0
       )
    end
  end

  test 'update' do
    assert @question.update(:question => 'Updated question'),
      @question.errors.full_messages.join('; ')
    @question.reload
    assert_equal 'Updated question', @question.question
  end

  test 'should delete' do
    assert_difference 'Question.count', -1 do
      @question.destroy
    end
  end

  test 'validates blank attributes' do
    @question.sort_order = nil
    @question.question = '  '
    @question.answer_type = nil

    assert @question.invalid?
    assert_error @question, :question, :blank
    assert_error @question, :sort_order, :blank
    assert_error @question, :answer_type, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @question.sort_order = '1.2'

    assert @question.invalid?
    assert_error @question, :sort_order, :not_an_integer
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @question.answer_type = Question::ANSWER_TYPES.values.sort.last.next

    assert @question.invalid?
    assert_error @question, :answer_type, :inclusion
  end

  test 'should return AnswerYesNo type name when is answer_yes_no' do
    question = questions :question_yes_no

    assert_equal AnswerYesNo.name, question.answer_type_name
  end

  test 'should return AnswerMultiChoice type name when is answer_multi_choice' do
    assert_equal AnswerMultiChoice.name, @question.answer_type_name
  end
  test 'should return AnswerWritten type name when is answer_written' do
    question = questions :question_written

    assert_equal AnswerWritten.name, question.answer_type_name
  end
end
