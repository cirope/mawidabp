require 'test_helper'

# Clase para probar el modelo "FindingRelation"
class FindingRelationTest < ActiveSupport::TestCase
  fixtures :finding_relations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding_relation = FindingRelation.find finding_relations(:iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification_duplicated_of_iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of FindingRelation, @finding_relation
    assert_equal finding_relations(:iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification_duplicated_of_iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).finding_relation_type,
      @finding_relation.finding_relation_type
    assert_equal finding_relations(:iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification_duplicated_of_iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).finding_id,
      @finding_relation.finding_id
    assert_equal finding_relations(:iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification_duplicated_of_iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).related_finding_id,
      @finding_relation.related_finding_id
  end

  # Prueba la creación de un perfil
  test 'create' do
    assert_difference 'FindingRelation.count' do
      @finding_relation = FindingRelation.create(
        :finding_relation_type => FindingRelation::TYPES[:duplicated],
        :finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
        :related_finding_id => findings(:iso_27000_security_policy_3_1_item_weakness).id
      )
    end
  end

  # Prueba de actualización de un perfil
  test 'update' do
    assert @finding_relation.duplicated?
    assert @finding_relation.update_attributes(
      :finding_relation_type => FindingRelation::TYPES[:related]),
      @finding_relation.errors.full_messages.join('; ')
    @finding_relation.reload
    assert @finding_relation.related?
  end

  # Prueba de eliminación de un perfil
  test 'delete' do
    assert_difference('FindingRelation.count', -1) { @finding_relation.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @finding_relation.related_finding_id = ' '
    @finding_relation.finding_relation_type = nil
    assert @finding_relation.invalid?
    assert_equal 2, @finding_relation.errors.count
    assert_equal error_message_from_model(@finding_relation,
      :related_finding_id, :blank),
      @finding_relation.errors.on(:related_finding_id)
    assert_equal error_message_from_model(@finding_relation,
      :finding_relation_type, :blank),
      @finding_relation.errors.on(:finding_relation_type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @finding_relation.finding_relation_type =
      FindingRelation::TYPES.values.sort.last.next
    assert @finding_relation.invalid?
    assert_equal 1, @finding_relation.errors.count
    assert_equal error_message_from_model(@finding_relation,
      :finding_relation_type, :inclusion),
      @finding_relation.errors.on(:finding_relation_type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    finding_relation = FindingRelation.find(finding_relations(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness_related_to_iso_27000_security_policy_3_1_item_weakness).id)

    finding_relation.finding.finding_relations.build(
      :related_finding => finding_relation.related_finding)
    assert finding_relation.invalid?
    assert_equal 1, finding_relation.errors.count
    assert_equal error_message_from_model(finding_relation, :related_finding_id,
      :taken), finding_relation.errors.on(:related_finding_id)
  end

  test 'dynamic functions' do
    FindingRelation::TYPES.each do |type, value|
      @finding_relation.finding_relation_type = value
      assert @finding_relation.send("#{type}?".to_sym)

      (FindingRelation::TYPES.values - [value]).each do |v|
        @finding_relation.finding_relation_type = v
        assert !@finding_relation.send("#{type}?".to_sym)
      end
    end
  end
end