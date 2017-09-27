require 'test_helper'

# Clase para probar el modelo "FindingRelation"
class FindingRelationTest < ActiveSupport::TestCase
  fixtures :finding_relations

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @finding_relation = FindingRelation.find finding_relations(:other_unconfirmed_for_notification_weakness_duplicated_of_unconfirmed_for_notification_weakness).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of FindingRelation, @finding_relation
    assert_equal finding_relations(:other_unconfirmed_for_notification_weakness_duplicated_of_unconfirmed_for_notification_weakness).description,
      @finding_relation.description
    assert_equal finding_relations(:other_unconfirmed_for_notification_weakness_duplicated_of_unconfirmed_for_notification_weakness).finding_id,
      @finding_relation.finding_id
    assert_equal finding_relations(:other_unconfirmed_for_notification_weakness_duplicated_of_unconfirmed_for_notification_weakness).related_finding_id,
      @finding_relation.related_finding_id
  end

  # Prueba la creación de un perfil
  test 'create' do
    assert_difference 'FindingRelation.count' do
      @finding_relation = FindingRelation.create(
        :description => 'Duplicated',
        :finding_id => findings(:unconfirmed_weakness).id,
        :related_finding_id => findings(:being_implemented_weakness_on_final).id
      )
    end
  end

  # Prueba de actualización de un perfil
  test 'update' do
    assert_equal 'Duplicated', @finding_relation.description
    assert @finding_relation.update(:description => 'Related'),
      @finding_relation.errors.full_messages.join('; ')
    @finding_relation.reload
    assert_equal 'Related', @finding_relation.description
  end

  # Prueba de eliminación de un perfil
  test 'delete' do
    assert_difference('FindingRelation.count', -1) { @finding_relation.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @finding_relation.related_finding_id = ' '
    @finding_relation.description = nil

    assert @finding_relation.invalid?
    assert_error @finding_relation, :related_finding_id, :blank
    assert_error @finding_relation, :description, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length attributes' do
    @finding_relation.description = 'abcde' * 52
    assert @finding_relation.invalid?

    assert_error @finding_relation, :description, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    finding_relation = FindingRelation.find(finding_relations(
        :unconfirmed_weakness_related_to_being_implemented_weakness_on_final).id)

    finding_relation.finding.finding_relations.build(
      :related_finding => finding_relation.related_finding)

    assert finding_relation.invalid?
    assert_error finding_relation, :related_finding_id, :taken
  end
end
