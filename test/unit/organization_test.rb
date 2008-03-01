require 'test_helper'

# Clase para probar el modelo "Organization"
class OrganizationTest < ActiveSupport::TestCase
  fixtures :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @organization = Organization.find organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Organization, @organization
    assert_equal organizations(:default_organization).name, @organization.name
    assert_equal organizations(:default_organization).prefix,
      @organization.prefix
    assert_equal organizations(:default_organization).description,
      @organization.description
    assert_equal organizations(:default_organization).image_model,
      @organization.image_model
  end

  # Prueba la creación de una organización
  test 'create' do
    assert_difference 'Organization.count' do
      assert_difference 'Parameter.count', DEFAULT_PARAMETERS.size do
        assert_difference 'Role.count', Role::TYPES.size do
          @organization = Organization.create(
            :name => 'new3 organization',
            :prefix => 'newww-test-prefix',
            :must_create_parameters => true,
            :must_create_roles => true
          )
        end
      end
    end
  end

  # Prueba de actualización de una organización
  test 'update' do
    assert @organization.update_attributes(:name => 'New name'),
      @organization.errors.full_messages.join('; ')
    @organization.reload
    assert_equal 'New name', @organization.name
  end

  # Prueba de eliminación de una organización
  test 'delete' do
    assert_difference 'Organization.count', -1 do
      @organization.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @organization.name = nil
    @organization.prefix = nil
    assert @organization.invalid?
    assert_equal 2, @organization.errors.count
    assert_equal error_message_from_model(@organization, :name, :blank),
      @organization.errors.on(:name)
    assert_equal error_message_from_model(@organization, :prefix, :blank),
      @organization.errors.on(:prefix)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @organization.name = 'abcdd' * 52
    @organization.prefix = 'abcdd' * 52
    assert @organization.invalid?
    assert_equal 2, @organization.errors.count
    assert_equal error_message_from_model(@organization, :name, :too_long,
      :count => 255), @organization.errors.on(:name)
    assert_equal error_message_from_model(@organization, :prefix, :too_long,
      :count => 255), @organization.errors.on(:prefix)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @organization.prefix = '?123'
    assert @organization.invalid?
    assert_equal 1, @organization.errors.count
    assert_equal error_message_from_model(@organization, :prefix, :invalid),
      @organization.errors.on(:prefix)

    @organization.prefix = 'abc_abc'
    assert @organization.invalid?
    assert_equal 1, @organization.errors.count
    assert_equal error_message_from_model(@organization, :prefix, :invalid),
      @organization.errors.on(:prefix)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @organization = Organization.new(
      :name => organizations(:default_organization).name,
      :prefix => organizations(:default_organization).prefix
    )

    assert @organization.invalid?
    assert_equal 2, @organization.errors.count
    assert_equal error_message_from_model(@organization, :name, :taken),
      @organization.errors.on(:name)
    assert_equal error_message_from_model(@organization, :prefix, :taken),
      @organization.errors.on(:prefix)
  end
end