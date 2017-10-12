require 'test_helper'

# Clase para probar el modelo "OldPassword"
class OldPasswordTest < ActiveSupport::TestCase
  fixtures :old_passwords, :users

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @old_password = OldPassword.find old_passwords(:administrator_old_password).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of OldPassword, @old_password
    assert_equal old_passwords(:administrator_old_password).password,
      @old_password.password
    assert_equal old_passwords(:administrator_old_password).user_id,
      @old_password.user_id
  end

  # Prueba la creación de una contraseña antigua
  test 'create' do
    assert_difference 'OldPassword.count' do
      @old_password = OldPassword.create(
        :password => 'New Old Password',
        :user => users(:administrator)
      )
    end
  end

  # Prueba de actualización de una contraseña antigua
  test 'update' do
    assert @old_password.update(:password => 'Updated Old Password'),
      @old_password.errors.full_messages.join('; ')
    @old_password.reload
    assert_equal 'Updated Old Password', @old_password.password
  end

  # Prueba de eliminación de una contraseñas antiguas
  test 'delete' do
    assert_difference('OldPassword.count', -1) { @old_password.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @old_password.password = 'abcdd' * 52

    assert @old_password.invalid?
    assert_error @old_password, :password, :too_long, count: 255
  end
end
