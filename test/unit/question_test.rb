# -*- coding: utf-8 -*-
require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  def setup
    @question = Question.find questions(:question_multi_choice).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Question, @question
    assert_equal questions(:question_multi_choice).question, @question.question
    assert_equal questions(:question_multi_choice).sort_order, @question.sort_order
    assert_equal questions(:question_multi_choice).answer_type, @question.answer_type
    assert_equal questions(:question_multi_choice).questionnaire_id, @question.questionnaire_id
  end

  # Prueba la creación de una cuestión
  test 'create' do
    assert_difference 'Question.count' do
      Question.create(
        :question => '¿Cual es su edad?',
        :sort_order => 1,
        :answer_type => 0
       )
    end
  end

  # Prueba de actualización de una cuestión
  test 'update' do
    assert @question.update_attributes(:question => 'Updated question'),
      @question.errors.full_messages.join('; ')
    @question.reload
    assert_equal 'Updated question', @question.question
  end

  # Prueba de eliminación de una cuestión
  test 'delete' do
    assert_difference 'Question.count', -1 do
      assert_difference 'AnswerOption.count', -5 do
        @question.destroy
      end
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @question.sort_order = nil
    @question.question = '  '
    @question.answer_type = nil
    assert @question.invalid?
    assert_equal 3, @question.errors.count
    assert_equal [error_message_from_model(@question, :question, :blank)],
      @question.errors[:question]
    assert_equal [error_message_from_model(@question, :sort_order, :blank)],
      @question.errors[:sort_order]
    assert_equal [error_message_from_model(@question, :answer_type, :blank)],
      @question.errors[:answer_type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @question.question = 'abcde' * 52
    assert @question.invalid?
    assert_equal 1, @question.errors.count
    assert_equal [error_message_from_model(@question, :question, :too_long,
      :count => 255)], @question.errors[:question]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @question.sort_order = '1.2'
    assert @question.invalid?
    assert_equal 1, @question.errors.count
    assert_equal [error_message_from_model(@question, :sort_order,
        :not_an_integer)], @question.errors[:sort_order]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @question.answer_type = Question::ANSWER_TYPES.values.sort.last.next
    assert @question.invalid?
    assert_equal 1, @question.errors.count
    assert_equal [error_message_from_model(@question, :answer_type, :inclusion)],
      @question.errors[:answer_type]
  end

   # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @question.question = questions(:question_written).question
    assert @question.invalid?
    assert_equal 1, @question.errors.count
    assert_equal [error_message_from_model(@question, :question, :taken)],
      @question.errors[:question]
  end
end
