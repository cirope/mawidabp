require 'test_helper'

# Clase para probar el modelo "OrganizationRole"
class OrganizationRoleTest < ActiveSupport::TestCase
  fixtures :organization_roles, :roles, :privileges

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @organization_role = OrganizationRole.find(
      organization_roles(:admin_role_for_administrator_user_in_default_organization).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_organization_role = organization_roles(
      :admin_role_for_administrator_user_in_default_organization)
    assert_kind_of OrganizationRole, @organization_role
    assert_equal fixture_organization_role.user_id, @organization_role.user_id
    assert_equal fixture_organization_role.organization_id,
      @organization_role.organization_id
    assert_equal fixture_organization_role.role_id, @organization_role.role_id
  end

  # Prueba la creación de un rol dentro de la organización
  test 'create' do
    assert_difference 'OrganizationRole.count' do
      @organization_role = OrganizationRole.create(
        :user => users(:administrator_user),
        :organization => organizations(:default_organization),
        :role => roles(:empty_admin_role)
      )
    end

    assert_equal users(:administrator_user).id,
      @organization_role.reload.user_id
  end

  # Prueba de actualización de un rol dentro de la organización
  test 'update' do
    assert @organization_role.update_attributes(
      :role => roles(:empty_admin_role)),
      @organization_role.errors.full_messages.join('; ')
    @organization_role.reload
    assert_equal roles(:empty_admin_role).id, @organization_role.role_id
  end

  # Prueba de eliminación de un rol dentro de la organización
  test 'destroy' do
    assert_difference('OrganizationRole.count', -1) do
      @organization_role.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @organization_role.organization_id = nil
    @organization_role.role_id = '   '
    assert @organization_role.invalid?
    assert_equal 2, @organization_role.errors.count
    assert_equal error_message_from_model(@organization_role, :organization_id,
      :blank), @organization_role.errors[:organization_id]
    assert_equal error_message_from_model(@organization_role, :role_id, :blank),
      @organization_role.errors[:role_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @organization_role.organization_id = '?nil'
    @organization_role.role_id = '?123'
    @organization_role.user_id = '12.2'
    assert @organization_role.invalid?
    assert_equal 3, @organization_role.errors.count
    assert_equal error_message_from_model(@organization_role, :organization_id,
      :not_a_number), @organization_role.errors[:organization_id]
    assert_equal error_message_from_model(@organization_role, :role_id,
      :not_a_number), @organization_role.errors[:role_id]
    assert_equal error_message_from_model(@organization_role, :user_id,
      :not_a_number), @organization_role.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    organization_role = OrganizationRole.new(
      @organization_role.attributes.merge(:id => nil))
    assert organization_role.invalid?
    assert_equal 1, organization_role.errors.count
    assert_equal error_message_from_model(organization_role, :role_id, :taken),
      organization_role.errors[:role_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates invalid roles' do
    user = User.find users(:administrator_second_user).id
    organization_role = user.organization_roles.build(
      :role => roles(:audited_role),
      :organization => organizations(:second_organization)
    )
    
    assert organization_role.invalid?
    assert_equal 1, organization_role.errors.count
    assert_equal error_message_from_model(organization_role, :role_id,
      :invalid), organization_role.errors[:role_id]
  end
end