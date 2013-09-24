require 'test_helper'

class AnswerOptionTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @answer_option = AnswerOption.find answer_options(:ao1).id
  end
  
  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of AnswerOption, @answer_option
    assert_equal answer_options(:ao1).option, @answer_option.option
    assert_equal answer_options(:ao1).question_id, @answer_option.question_id    
  end
  
  # Prueba la creación de una opción de respuesta
  test 'create' do
    assert_difference 'AnswerOption.count' do
      AnswerOption.create(
        :option => 'De acuerdo',
        :question_id => questions(:question_written).id
      )
    end
  end
  
  # Prueba de actualización de una opción de respuesta
  test 'update' do
    assert @answer_option.update(:option => 'Updated option'),
      @answer_option.errors.full_messages.join('; ')
    @answer_option.reload
    assert_equal 'Updated option', @answer_option.option
  end
  
  # Prueba de eliminación de items de ayuda
  test 'delete' do
    assert_difference('AnswerOption.count', -1) { @answer_option.destroy }
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @answer_option.option = '  '
    assert @answer_option.invalid?
    assert_equal 1, @answer_option.errors.count
    assert_equal [error_message_from_model(@answer_option, :option, :blank)],
      @answer_option.errors[:option]
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @answer_option.option = 'abcde' * 52
    assert @answer_option.invalid?
    assert_equal 1, @answer_option.errors.count
    assert_equal [error_message_from_model(@answer_option, :option, :too_long,
      :count => 255)], @answer_option.errors[:option]
  end
end
