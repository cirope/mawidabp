require 'test_helper'

# Clase para probar el modelo "LoginRecord"
class LoginRecordTest < ActiveSupport::TestCase
  fixtures :login_records, :users

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @login_record = LoginRecord.find(
      login_records(:administrator_user_success_login_record).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of LoginRecord, @login_record
    assert_equal login_records(:administrator_user_success_login_record).start,
      @login_record.start
    assert_equal login_records(:administrator_user_success_login_record).end,
      @login_record.end
    assert_equal login_records(:administrator_user_success_login_record).data,
      @login_record.data
    assert_equal login_records(:administrator_user_success_login_record).user_id,
      @login_record.user_id
    assert_equal login_records(:administrator_user_success_login_record).
      organization_id, @login_record.organization_id
  end

  # Prueba la creación de un registro de ingreso
  test 'create' do
    assert_difference 'LoginRecord.count' do
      @login_record = LoginRecord.create(
        :start => 2.hours.ago,
        :end => Time.now,
        :user_id => users(:administrator_user).id,
        :organization_id => organizations(:default_organization).id,
        :data => 'Some data'
      )
    end
  end

  # Prueba de actualización de un registro de ingreso
  test 'update' do
    assert @login_record.update_attributes(:data => 'New data'),
      @login_record.errors.full_messages.join('; ')
    @login_record.reload
    assert_equal 'New data', @login_record.data
  end

  # Prueba de eliminación de un registro de ingreso
  test 'destroy' do
    assert_difference 'LoginRecord.count', -1 do
      @login_record.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates nil attributes' do
    @login_record.user_id = nil
    @login_record.organization_id = nil
    assert @login_record.invalid?
    assert_equal 2, @login_record.errors.count
    assert_equal [error_message_from_model(@login_record, :user_id, :blank)],
      @login_record.errors[:user_id]
    assert_equal [error_message_from_model(@login_record, :organization_id,
      :blank)], @login_record.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates dates attributes' do
    @login_record.start = Time.now
    @login_record.end = 10.hours.ago
    assert @login_record.invalid?
    assert_equal 1, @login_record.errors.count
    assert_equal [error_message_from_model(@login_record, :end, :after,
      :restriction => I18n.l(@login_record.start, :format => :validation))],
      @login_record.errors[:end]

    @login_record.reload
    @login_record.start = 'XX'
    assert @login_record.invalid?
    assert_equal 2, @login_record.errors.count
    assert_equal [error_message_from_model(@login_record, :start, :blank),
      error_message_from_model(@login_record, :start, :invalid_date)].sort,
      @login_record.errors[:start].sort

    @login_record.reload
    @login_record.start = ''
    @login_record.end = ''
    assert @login_record.invalid?
    assert_equal 2, @login_record.errors.count
    assert_equal [error_message_from_model(@login_record, :start, :blank)],
      @login_record.errors[:start]
    assert_equal [error_message_from_model(@login_record, :end, :invalid_date)],
      @login_record.errors[:end]
  end
end