require 'test_helper'

# Clase para probar el modelo "InlineHelp"
class InlineHelpTest < ActiveSupport::TestCase
  fixtures :inline_helps

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @inline_help = InlineHelp.find inline_helps(:es_review_identification).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of InlineHelp, @inline_help
    assert_equal inline_helps(:es_review_identification).language,
      @inline_help.language
    assert_equal inline_helps(:es_review_identification).name, @inline_help.name
    assert_equal inline_helps(:es_review_identification).content,
      @inline_help.content
  end

  # Prueba la creación de un contenido de ayuda en línea
  test 'create' do
    assert_difference 'InlineHelp.count' do
      @inline_help = InlineHelp.create(
        :language => 'it',
        :name => 'review_score',
        :content => 'Review score explanation'
      )
    end
  end

  # Prueba de actualización de un contenido de ayuda en línea
  test 'update' do
    assert @inline_help.update(:content => 'Updated content'),
      @inline_help.errors.full_messages.join('; ')
    @inline_help.reload
    assert_equal 'Updated content', @inline_help.content
  end

  # Prueba de eliminación de contenidos de ayuda en línea
  test 'delete' do
    assert_difference('InlineHelp.count', -1) { @inline_help.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @inline_help.language = '   '
    @inline_help.name = '   '
    assert @inline_help.invalid?
    assert_equal 2, @inline_help.errors.count
    assert_equal [error_message_from_model(@inline_help, :language, :blank)],
      @inline_help.errors[:language]
    assert_equal [error_message_from_model(@inline_help, :name, :blank)],
      @inline_help.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @inline_help.name = inline_helps(:es_review_score).name
    assert @inline_help.invalid?
    assert_equal 1, @inline_help.errors.count
    assert_equal [error_message_from_model(@inline_help, :name, :taken)],
      @inline_help.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @inline_help.language = 'abcd' * 3
    @inline_help.name = 'abcde' * 52
    assert @inline_help.invalid?
    assert_equal 2, @inline_help.errors.count
    assert_equal [error_message_from_model(@inline_help, :language, :too_long,
      :count => 10)], @inline_help.errors[:language]
    assert_equal [error_message_from_model(@inline_help, :name, :too_long,
      :count => 255)], @inline_help.errors[:name]
  end
end
