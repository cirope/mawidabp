require 'test_helper'

# Clase para probar el modelo "NotificationRelation"
class NotificationRelationTest < ActiveSupport::TestCase
  fixtures :notification_relations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @notification_relation = NotificationRelation.find notification_relations(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed_relation).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_notification_relation = notification_relations(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed_relation)
    assert_kind_of NotificationRelation, @notification_relation
    assert_equal fixture_notification_relation.model_id,
      @notification_relation.model_id
    assert_equal fixture_notification_relation.model_type,
      @notification_relation.model_type
    assert_equal fixture_notification_relation.notification_id,
      @notification_relation.notification_id
  end

  # Prueba la creación de una relación de actualización
  test 'create' do
    assert_difference 'NotificationRelation.count' do
      @notification_relation = NotificationRelation.create(
        :model => Weakness.find(findings(
            :bcra_A4609_security_management_responsible_dependency_weakness_notify).id),
        :notification => Notification.find(notifications(
            :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id)
      )

      assert_equal 'Finding', @notification_relation.model_type
    end
  end

  # Prueba de actualización de una relación de actualización
  test 'update' do
    fixture_finding = findings(
      :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification)
    assert @notification_relation.update_attributes(
      :model => Weakness.find(fixture_finding.id)),
      @notification_relation.errors.full_messages.join('; ')
    @notification_relation.reload
    assert_equal fixture_finding.id, @notification_relation.model_id
  end

  # Prueba de eliminación de una relación de notificación
  test 'delete' do
    assert_difference('NotificationRelation.count', -1) do
      @notification_relation.destroy
    end
  end
end