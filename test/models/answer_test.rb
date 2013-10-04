require 'test_helper'

class AnswerTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
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

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    # Cuestión escrita
    assert @answer.valid?
    assert_equal 0, @answer.errors.count
    @answer.answer = '  '
    @answer.save
    assert @answer.invalid?
    assert_equal 1, @answer.errors.count
    assert_equal [error_message_from_model(@answer, :answer, :blank)],
      @answer.errors[:answer]
    # Cuestión multi choice
    answer = answers(:answer_multi_choice)
    assert answer.valid?
    assert_equal 0, answer.errors.count
    answer.answer_option = nil
    answer.save
    assert answer.invalid?
    assert_equal 1, answer.errors.count
    assert_equal [error_message_from_model(answer, :answer_option, :blank)],
      answer.errors[:answer_option]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @answer.answer = 'abcde' * 52
    assert @answer.invalid?
    assert_equal 1, @answer.errors.count
    assert_equal [error_message_from_model(@answer, :answer, :too_long,
      count: 255)], @answer.errors[:answer]
  end
end
