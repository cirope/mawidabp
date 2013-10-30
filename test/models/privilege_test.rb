require 'test_helper'

# Clase para probar el modelo "Privilege"
class PrivilegeTest < ActiveSupport::TestCase
  fixtures :privileges, :roles

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @privilege = Privilege.find privileges(:admin_administration_settings).id
    @privilege.role.inject_auth_privileges(Hash.new(Hash.new(true)))
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Privilege, @privilege
    assert_equal privileges(:admin_administration_settings).module,
      @privilege.module
    assert_equal privileges(:admin_administration_settings).approval,
      @privilege.approval
    assert_equal privileges(:admin_administration_settings).erase,
      @privilege.erase
    assert_equal privileges(:admin_administration_settings).modify,
      @privilege.modify
    assert_equal privileges(:admin_administration_settings).read,
      @privilege.read
  end

  # Prueba la creación de un privilegio
  test 'create' do
    assert_difference 'Privilege.count' do
      @privilege = Privilege.new(
        :module => roles(:empty_admin_role).allowed_modules.first.to_s,
        :approval => true,
        :erase => true,
        :modify => true,
        :read => true,
        :role_id => roles(:empty_admin_role).id
      )

      @privilege.role.inject_auth_privileges(Hash.new(Hash.new(true)))

      assert @privilege.save
    end
  end

  # Prueba de actualización de un privilegio
  test 'update' do
    assert @privilege.erase
    assert @privilege.update(:erase => false),
      @privilege.errors.full_messages.join('; ')
    @privilege.reload
    assert_equal false, @privilege.erase
  end

  # Prueba de eliminación de un privilegio
  test 'delete' do
    assert_difference 'Privilege.count', -1 do
      @privilege.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @privilege.module = nil
    assert @privilege.invalid?
    assert_equal 1, @privilege.errors.count
    assert_equal [error_message_from_model(@privilege, :module, :blank)],
      @privilege.errors[:module]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @privilege.module = 'abcdd' * 52
    assert @privilege.invalid?
    assert_equal 3, @privilege.errors.count
    assert_equal [error_message_from_model(@privilege, :module, :too_long,
      :count => 255), error_message_from_model(@privilege, :module, :inclusion),
    error_message_from_model(@privilege, :module, :invalid)].sort,
    @privilege.errors[:module].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @privilege.module = 'fake_controller'
    assert @privilege.invalid?
    assert_equal 2, @privilege.errors.count
    assert_equal [error_message_from_model(@privilege, :module, :inclusion),
      error_message_from_model(@privilege, :module, :invalid)].sort,
      @privilege.errors[:module].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @privilege.module = privileges(:admin_follow_up_notifications).module
    assert @privilege.invalid?
    assert_equal 1, @privilege.errors.count
    assert_equal [error_message_from_model(@privilege, :module, :taken)],
      @privilege.errors[:module]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates role allow module in privileges' do
    @privilege = Privilege.find(privileges(:audited_follow_up_notifications).id)
    @privilege.module = 'administration_settings'
    assert @privilege.invalid?
    assert_equal 1, @privilege.errors.count
    assert_equal [error_message_from_model(@privilege, :module, :invalid)],
      @privilege.errors[:module]
  end

  test 'mark implicit privileges function' do
    assert @privilege.approval && @privilege.erase && @privilege.modify &&
      @privilege.read
    
    @privilege.approval = false
    @privilege.mark_implicit_privileges
    
    assert !@privilege.approval && @privilege.erase && @privilege.modify &&
      @privilege.read
    
    @privilege.erase = false
    @privilege.mark_implicit_privileges
    
    assert !@privilege.approval && !@privilege.erase && @privilege.modify &&
      @privilege.read
    
    @privilege.modify = false
    @privilege.mark_implicit_privileges
    
    assert !@privilege.approval && !@privilege.erase && !@privilege.modify &&
      @privilege.read
    
    @privilege.read = false
    @privilege.mark_implicit_privileges
    
    assert !@privilege.approval && !@privilege.erase && !@privilege.modify &&
      !@privilege.read

    @privilege.modify = true
    @privilege.mark_implicit_privileges

    assert !@privilege.approval && !@privilege.erase && @privilege.modify &&
      @privilege.read

    @privilege.modify = @privilege.read = false
    @privilege.erase = true
    @privilege.mark_implicit_privileges

    assert !@privilege.approval && @privilege.erase && @privilege.modify &&
      @privilege.read

    @privilege.erase = @privilege.modify = @privilege.read = false
    @privilege.approval = true
    @privilege.mark_implicit_privileges

    assert @privilege.approval && !@privilege.erase && !@privilege.modify &&
      @privilege.read
  end
end
