require 'test_helper'

# Clase para probar el modelo "Role"
class RoleTest < ActiveSupport::TestCase
  fixtures :roles

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @role = Role.find roles(:admin_role).id
    @role.inject_auth_privileges(Hash.new(Hash.new(true)))
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Role, @role
    assert_equal roles(:admin_role).name, @role.name
    assert_equal roles(:admin_role).privilege_ids, @role.privilege_ids
  end

  # Prueba la creación de un perfil
  test 'create' do
    assert_difference 'Role.count' do
      @role = Role.new(
        :name => 'New name',
        :role_type => Role::TYPES[:admin],
        :organization_id => organizations(:default_organization).id
      )

      @role.inject_auth_privileges(Hash.new(Hash.new(true)))

      assert @role.save
    end
  end

  # Prueba de actualización de un perfil
  test 'update' do
    assert @role.update(:name => 'Updated name'),
      @role.errors.full_messages.join('; ')
    @role.reload
    assert_equal 'Updated name', @role.name
  end

  # Prueba de eliminación de un perfil
  test 'delete' do
    assert_difference 'Role.count', -1 do
      @role.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @role.name = '?nil'
    @role.organization_id = 'xx'
    assert @role.invalid?
    assert_equal 2, @role.errors.count
    assert_equal [error_message_from_model(@role, :name, :invalid)],
      @role.errors[:name]
    assert_equal [error_message_from_model(@role, :organization_id,
      :not_a_number)], @role.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @role.name = nil
    @role.organization_id = ' '
    @role.role_type = nil
    assert @role.invalid?
    assert_equal 3, @role.errors.count
    assert_equal [error_message_from_model(@role, :name, :blank)],
      @role.errors[:name]
    assert_equal [error_message_from_model(@role, :organization_id, :blank)],
      @role.errors[:organization_id]
    assert_equal [error_message_from_model(@role, :role_type, :blank)],
      @role.errors[:role_type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @role.name = 'abcdd' * 52
    assert @role.invalid?
    assert_equal 1, @role.errors.count
    assert_equal [error_message_from_model(@role, :name, :too_long,
      :count => 255)], @role.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @role.role_type = Role::TYPES.values.sort.last.next
    assert @role.invalid?
    assert_equal 1, @role.errors.count
    assert_equal [error_message_from_model(@role, :role_type, :inclusion)],
      @role.errors[:role_type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @role.name = roles(:auditor_senior_role).name
    assert @role.invalid?
    assert_equal 1, @role.errors.count
    assert_equal [error_message_from_model(@role, :name, :taken)],
      @role.errors[:name]
  end

  test 'allowed controllers' do
    assert !@role.allowed_modules.empty?
    assert_equal ALLOWED_MODULES_BY_TYPE[@role.get_type],
      @role.allowed_modules
  end

  test 'check auth privileges function' do
    @role = Role.new

    assert_raise(RuntimeError) { @role.check_auth_privileges }
  end

  test 'inject auth privileges and has auth privileges function' do
    @role = Role.new
    bare_role_privileges = roles(:auditor_senior_role).privileges_hash

    assert !@role.has_auth_privileges?
    assert bare_role_privileges.size > 0

    @role.inject_auth_privileges(bare_role_privileges)
    assert @role.has_auth_privileges?
  end

  test 'auth privileges for function' do
    bare_role_privileges = roles(:auditor_senior_role).privileges_hash

    assert bare_role_privileges.size > 0
    @role.inject_auth_privileges(bare_role_privileges)
    assert @role.has_auth_privileges?

    bare_role_privileges.each do |module_name, privileges|
      assert_equal privileges, @role.auth_privileges_for(module_name)
    end
  end

  test 'has privilege for functions' do
    assert @role.privileges.size > 2
    # Para asegurar un negativo
    assert Privilege.find(privileges(:admin_administration_settings).id).
      update(:read => false, :modify => false, :erase => false,
      :approval => false)

    @role.privileges(true).each do |p|
      if p.read? || p.modify? || p.erase? || p.approval?
        assert @role.has_privilege_for?(p.module)
        assert !(@role.has_privilege_for_read?(p.module) ^ p.read?)
        assert !(@role.has_privilege_for_modify?(p.module) ^ p.modify?)
        assert !(@role.has_privilege_for_erase?(p.module) ^ p.erase?)
        assert !(@role.has_privilege_for_approval?(p.module) ^ p.approval?)
      else
        assert !@role.has_privilege_for?(p.module)
        assert !@role.has_privilege_for_read?(p.module) && !p.read?
        assert !@role.has_privilege_for_modify?(p.module) && !p.modify?
        assert !@role.has_privilege_for_erase?(p.module) && !p.erase?
        assert !@role.has_privilege_for_approval?(p.module) && !p.approval?
      end
    end
  end

  test 'is touched when a privilege is updated' do
    updated_at = @role.updated_at

    assert @role.update(
      :privileges_attributes => {
        privileges(:admin_administration_settings).id => {
          :id => privileges(:admin_administration_settings).id,
          :approval => false,
          :erase => false,
          :modify => false,
          :read => false,
        }
      }
    )

    assert_not_equal updated_at, @role.reload.updated_at
  end

  test 'dynamic functions' do
    Role::TYPES.each do |type, value|
      @role.role_type = value
      assert @role.send(:"#{type}?")

      (Role::TYPES.values - [value]).each do |v|
        @role.role_type = v
        assert !@role.send(:"#{type}?")
      end
    end
  end
end
