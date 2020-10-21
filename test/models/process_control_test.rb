require 'test_helper'

# Clase para probar el modelo "ProcessControl"
class ProcessControlTest < ActiveSupport::TestCase
  fixtures :process_controls

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @process_control = ProcessControl.find(
      process_controls(:security_policy).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ProcessControl, @process_control
    assert_equal process_controls(:security_policy).name,
      @process_control.name
    assert_equal process_controls(:security_policy).order,
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
    assert @process_control.update(:name => 'Updated name'),
      @process_control.errors.full_messages.join('; ')
    @process_control.reload
    assert_equal 'Updated name', @process_control.name
  end

  # Prueba de eliminación de un proceso de control
  test 'destroy' do
    assert_difference 'ProcessControl.count', -1 do
      process_controls(:data_processing).destroy
    end
  end

  test 'destroy with asociated control objectives' do
    assert_no_difference 'ProcessControl.count' do
      assert_raise ActiveRecord::RecordNotDestroyed do
        @process_control.destroy!
      end
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @process_control.name = nil
    @process_control.order = nil

    assert @process_control.invalid?
    assert_error @process_control, :name, :blank
    assert_error @process_control, :order, :blank
    assert_error @process_control, :order, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @process_control.name = 'abcdd' * 52

    assert @process_control.invalid?
    assert_error @process_control, :name, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @process_control.name = process_controls(:organization_security).name

    assert @process_control.invalid?
    assert_error @process_control, :name, :taken
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @process_control.order = 'not a number'

    assert @process_control.invalid?
    assert_error @process_control, :order, :not_a_number
  end

  test 'hide obsolete process controls' do
    organization         = organizations :cirope
    Current.organization = organization # Since we use list below

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '1'

    assert_difference 'ProcessControl.visible.count', -1 do
      @process_control.update!(obsolete: true)
    end

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '0'

    assert_equal ProcessControl.visible.count, ProcessControl.count

  ensure
    Current.organization = nil
  end
end
