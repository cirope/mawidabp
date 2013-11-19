require 'test_helper'

# Clase para probar el modelo "Organization"
class OrganizationTest < ActiveSupport::TestCase
  fixtures :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @organization = Organization.find organizations(:default_organization).id
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Organization, @organization
    assert_equal organizations(:default_organization).name, @organization.name
    assert_equal organizations(:default_organization).prefix,
      @organization.prefix
    assert_equal organizations(:default_organization).description,
      @organization.description
    assert_equal organizations(:default_organization).group_id,
      @organization.group_id
    assert_equal organizations(:default_organization).image_model_id,
      @organization.image_model_id
  end

  # Prueba la creación de una organización
  test 'create' do
    assert_difference 'Organization.count' do
      assert_difference 'Setting.count', DEFAULT_SETTINGS.size do
        assert_difference 'Role.count', Role::TYPES.size do
          @organization = Organization.create(
            :name => 'new3 organization',
            :prefix => 'newww-test-prefix',
            :kind => 'public'
          )
        end
      end
    end

    assert_equal groups(:main_group).id,
      Organization.find_by_prefix('newww-test-prefix').group_id
  end

  # Prueba la creación de una organización
  test 'create with wrong group' do
    assert_difference 'Organization.count' do
      assert_difference 'Setting.count', DEFAULT_SETTINGS.size do
        assert_difference 'Role.count', Role::TYPES.size do
          @organization = Organization.create(
            :name => 'new3 organization',
            :prefix => 'newww-test-prefix',
            :kind => 'quality_management',
            :group_id => groups(:second_group).id
          )
        end
      end
    end

    # El grupo debe ser el mismo que el de la organización autenticada
    assert_equal groups(:main_group).id,
      Organization.find_by_prefix('newww-test-prefix').group_id
  end

  # Prueba de actualización de una organización
  test 'update' do
    assert @organization.update(:name => 'New name'),
      @organization.errors.full_messages.join('; ')
    @organization.reload
    assert_equal 'New name', @organization.name
  end

  # Prueba de eliminación de una organización
  test 'delete' do
    organization = Organization.find organizations(:second_organization).id

    assert_difference ['ImageModel.count', 'Organization.count'], -1 do
      organization.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @organization.name = nil
    @organization.prefix = nil
    @organization.kind = nil

    assert @organization.invalid?
    assert_error @organization, :name, :blank
    assert_error @organization, :prefix, :blank
    assert_error @organization, :kind, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @organization.name = 'abcdd' * 52
    @organization.prefix = 'abcdd' * 52

    assert @organization.invalid?
    assert_error @organization, :name, :too_long, count: 255
    assert_error @organization, :prefix, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @organization.prefix = '?123'

    assert @organization.invalid?
    assert_error @organization, :prefix, :invalid

    @organization.prefix = 'abc_abc'

    assert @organization.invalid?
    assert_error @organization, :prefix, :invalid
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @organization = Organization.new(
      :name => organizations(:default_organization).name,
      :prefix => organizations(:default_organization).prefix
    )

    assert @organization.invalid?
    assert_error @organization, :name, :taken
    assert_error @organization, :prefix, :taken

    @organization.group_id = groups(:second_group).id

    assert @organization.invalid?
    assert_error @organization, :prefix, :taken
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates excluded attributes' do
    @organization.prefix = Organization::INVALID_PREFIXES.first

    assert @organization.invalid?
    assert_error @organization, :prefix, :exclusion
  end

  test 'validates included attributes' do
    @organization.kind = 'another_kind'

    assert @organization.invalid?
    assert_error @organization, :kind, :inclusion
  end
end
