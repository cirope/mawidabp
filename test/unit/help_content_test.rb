require 'test_helper'

# Clase para probar el modelo "HelpContent"
class HelpContentTest < ActiveSupport::TestCase
  fixtures :help_contents

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @help_content = HelpContent.find help_contents(:help_es).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of HelpContent, @help_content
    assert_equal help_contents(:help_es).language, @help_content.language
  end

  # Prueba la creación de un contenido de ayuda
  test 'create' do
    assert_difference 'HelpContent.count' do
      @help_content = HelpContent.create(:language => 'it')
    end
  end

  # Prueba de actualización de un contenido de ayuda
  test 'update' do
    assert @help_content.update_attributes(:language => 'jp'),
      @help_content.errors.full_messages.join('; ')
    @help_content.reload
    assert_equal 'jp', @help_content.language
  end

  # Prueba de eliminación de contenidos de ayuda
  test 'delete' do
    assert_difference('HelpContent.count', -1) { @help_content.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @help_content.language = '   '
    assert @help_content.invalid?
    assert_equal 1, @help_content.errors.count
    assert_equal error_message_from_model(@help_content, :language, :blank),
      @help_content.errors[:language]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @help_content.language = help_contents(:help_en).language
    assert @help_content.invalid?
    assert_equal 1, @help_content.errors.count
    assert_equal error_message_from_model(@help_content, :language, :taken),
      @help_content.errors[:language]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @help_content.language = 'abcd' * 3
    assert @help_content.invalid?
    assert_equal 1, @help_content.errors.count
    assert_equal error_message_from_model(@help_content, :language, :too_long,
      :count => 10), @help_content.errors[:language]
  end
end