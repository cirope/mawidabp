require 'test_helper'

# Clase para probar el modelo "ErrorRecord"
class ErrorRecordTest < ActiveSupport::TestCase
  fixtures :error_records, :users

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @error_record = ErrorRecord.find(
      error_records(:administrator_user_failed_attempt).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ErrorRecord, @error_record
    assert_equal error_records(:administrator_user_failed_attempt).error,
      @error_record.error
    assert_equal error_records(:administrator_user_failed_attempt).data,
      @error_record.data
    assert_equal error_records(:administrator_user_failed_attempt).user_id,
      @error_record.user_id
  end

  # Prueba la creación de un registro de error
  test 'create' do
    assert_difference 'ErrorRecord.count' do
      @error_record = ErrorRecord.create(
        :error => 1,
        :data => 'Some data',
        :user_id => users(:administrator_user).id
      )
    end
  end

  # Prueba de actualización de un registro de error
  test 'update' do
    assert @error_record.update_attributes(:data => 'New data'),
      @error_record.errors.full_messages.join('; ')
    @error_record.reload
    assert_equal 'New data', @error_record.data
  end

  # Prueba de eliminación de un registro de ingreso
  test 'delete' do
    assert_difference 'ErrorRecord.count', -1 do
      @error_record.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates inclusion attributes' do
    @error_record.error = ErrorRecord::ERRORS.values.sort.last.next
    assert @error_record.invalid?
    assert_equal 1, @error_record.errors.count
    assert_equal error_message_from_model(@error_record, :error, :inclusion),
      @error_record.errors[:error]
  end
end