require 'test_helper'

class AnswerTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @answer = Answer.find answers(:answer_written).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Answer, @answer
    assert_equal answers(:answer_written).answer, @answer.answer
    assert_equal answers(:answer_written).comments, @answer.comments
    assert_equal answers(:answer_written).type, @answer.type
  end

  # Prueba la creación de una respuesta
  test 'create' do
    assert_difference 'Answer.count' do
      Answer.create(
        answer: 'Nueva respuesta',
        type: AnswerWritten.name,
        question_id: questions(:question_written).id,
        poll_id: polls(:poll_one).id
      )
    end
  end

  # Prueba de actualización de una respuesta
  test 'update' do
    assert @answer.update(answer: 'Updated answer'),
      @answer.errors.full_messages.join('; ')

    assert_equal 'Updated answer', @answer.answer
  end

  # Prueba de eliminación de respuesta
  test 'delete' do
    assert_difference('Answer.count', -1) { @answer.destroy }
  end

  test 'invalid answer type' do
    @answer.type = 'test'

    refute @answer.valid?
    assert_error @answer, :type, :inclusion
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @answer.answer = 'abcde' * 52

    assert @answer.invalid?
    assert_error @answer, :answer, :too_long, count: 255
  end

  test 'must be incompleted when is blank answer' do
    @answer.answer = ''

    refute @answer.completed?

    @answer.answer = nil

    refute @answer.completed?
  end

  test 'must be completed when is present answer' do
    assert @answer.completed?
  end

  test 'must be incompleted when is blank answer option' do
    answer_yes_no = answers :answer_yes_no

    refute answer_yes_no.completed?

    answer_multi_choice               = answers :answer_multi_choice
    answer_multi_choice.answer_option = nil

    refute answer_multi_choice.completed?
  end

  test 'must be completed when is present answer option' do
    answer_yes_no               = answers :answer_yes_no
    answer_yes_no.answer_option = answer_options :yes_no_no

    assert answer_yes_no.completed?

    answer_multi_choice = answers :answer_multi_choice

    assert answer_multi_choice.completed?
  end
end
