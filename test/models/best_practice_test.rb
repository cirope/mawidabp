require 'test_helper'

# Clase para probar el modelo "BestPractice"
class BestPracticeTest < ActiveSupport::TestCase
  fixtures :best_practices, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    set_organization
    @best_practice = BestPractice.find best_practices(:iso_27001).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of BestPractice, @best_practice
    assert_equal best_practices(:iso_27001).name, @best_practice.name
    assert_equal best_practices(:iso_27001).description,
      @best_practice.description
  end

  # Prueba la creación de una buena práctica
  test 'create' do
    assert_difference 'BestPractice.count' do
      @best_practice = BestPractice.create(
        :name => 'New name',
        :description => 'New description'
      )
    end

    assert_equal organizations(:default_organization).id,
      @best_practice.organization_id
  end

  # Prueba de actualización de una buena práctica
  test 'update' do
    assert @best_practice.update(:name => 'Updated name'),
      @best_practice.errors.full_messages.join('; ')
    @best_practice.reload
    assert_equal 'Updated name', @best_practice.name
  end

  # Prueba de eliminación de una buena práctica
  test 'destroy' do
    assert_difference 'BestPractice.count', -1 do
      BestPractice.find(best_practices(:useless_best_practice).id).destroy
    end
  end

  test 'destroy with asociated control objectives' do
    assert_no_difference 'BestPractice.count' do
      @best_practice.destroy
    end

    assert_equal 1, @best_practice.errors.size
    assert_equal I18n.t('control_objective.errors.related'),
      @best_practice.errors.full_messages.join
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank atrtributes' do
    @best_practice.name = nil
    @best_practice.organization_id = '  '

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :blank
    assert_error @best_practice, :organization_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @best_practice.name = 'abcdd' * 52

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :too_long, count: 255
  end

  test 'validates formated attributes' do
    @best_practice.organization_id = 'a'

    assert @best_practice.invalid?
    assert_error @best_practice, :organization_id, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @best_practice.name = best_practices(:bcra_A4609).name

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :taken
  end
end
