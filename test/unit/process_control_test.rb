require 'test_helper'

# Clase para probar el modelo "ProcessControl"
class ProcessControlTest < ActiveSupport::TestCase
  fixtures :process_controls

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @process_control = ProcessControl.find(
      process_controls(:iso_27000_security_policy).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ProcessControl, @process_control
    assert_equal process_controls(:iso_27000_security_policy).name,
      @process_control.name
    assert_equal process_controls(:iso_27000_security_policy).order,
      @process_control.order
  end

  # Prueba la creación de un proceso de control
  test 'create' do
    assert_difference 'ProcessControl.count' do
      @process_control = ProcessControl.create(
        :name => 'New name',
        :order => 1
      )
    end
  end

  # Prueba de actualización de un proceso de control
  test 'update' do
    assert @process_control.update_attributes(:name => 'Updated name'),
      @process_control.errors.full_messages.join('; ')
    @process_control.reload
    assert_equal 'Updated name', @process_control.name
  end

  # Prueba de eliminación de un proceso de control
  test 'destroy' do
    assert_difference 'ProcessControl.count', -1 do
      ProcessControl.find(process_controls(:bcra_A4609_data_proccessing).id).
        destroy
    end
  end

  test 'destroy with asociated control objectives' do
    assert_no_difference 'ProcessControl.count' do
      @process_control.destroy
    end

    assert_equal 1, @process_control.errors.size
    assert_equal I18n.t('control_objective.errors.related'),
      @process_control.errors.full_messages.join
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @process_control.name = nil
    @process_control.order = nil
    assert @process_control.invalid?
    assert_equal 3, @process_control.errors.count
    assert_equal [error_message_from_model(@process_control, :name, :blank)],
      @process_control.errors[:name]
    assert_equal [error_message_from_model(@process_control, :order, :blank),
      error_message_from_model(@process_control, :order, :not_a_number)].sort,
      @process_control.errors[:order].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @process_control.name = 'abcdd' * 52
    assert @process_control.invalid?
    assert_equal 1, @process_control.errors.count
    assert_equal [error_message_from_model(@process_control, :name, :too_long,
      :count => 255)], @process_control.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @process_control.name =
      process_controls(:iso_27000_security_organization).name
    assert @process_control.invalid?
    assert_equal 1, @process_control.errors.count
    assert_equal [error_message_from_model(@process_control, :name, :taken)],
      @process_control.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @process_control.order = 'not a number'
    assert @process_control.invalid?
    assert_equal 1, @process_control.errors.count
    assert_equal [error_message_from_model(@process_control, :order,
      :not_a_number)], @process_control.errors[:order]
  end
end