require 'test_helper'

class RelatedUserRelationTest < ActiveSupport::TestCase
  fixtures :related_user_relations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @related_user_relation = RelatedUserRelation.find(
      related_user_relations(:bare_user_first_time_user_relation).id
    )
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of RelatedUserRelation, @related_user_relation
    assert_equal related_user_relations(:bare_user_first_time_user_relation).user_id,
      @related_user_relation.user_id
    assert_equal related_user_relations(:bare_user_first_time_user_relation).related_user_id,
      @related_user_relation.related_user_id
  end

  # Prueba la creación de un perfil
  test 'create' do
    assert_difference 'RelatedUserRelation.count' do
      @related_user_relation = RelatedUserRelation.create(
        :user => users(:plain_manager_user),
        :related_user => users(:manager_user)
      )
    end
  end

  # Prueba de actualización de un perfil
  test 'update' do
    assert @related_user_relation.update(
      :related_user => users(:manager_user)
    ), @related_user_relation.errors.full_messages.join('; ')
    
    @related_user_relation.reload
    assert_equal users(:manager_user).id, @related_user_relation.related_user_id
  end

  # Prueba de eliminación de un perfil
  test 'delete' do
    assert_difference('RelatedUserRelation.count', -1) do
      @related_user_relation.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @related_user_relation.related_user = nil

    assert @related_user_relation.invalid?
    assert_error @related_user_relation, :related_user, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    related_user_relation = RelatedUserRelation.find(
      related_user_relations(:general_manager_user_coordinator_manager_user_relation).id
    )
    @related_user_relation.user = related_user_relation.user
    @related_user_relation.related_user = related_user_relation.related_user

    assert @related_user_relation.invalid?
    assert_error @related_user_relation, :related_user_id, :taken
  end
end
