require 'test_helper'

# Clase para probar el modelo "Notification"
class NotificationTest < ActiveSupport::TestCase
  fixtures :notifications, :users, :findings

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @notification = Notification.find(
      notifications(:administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).id)
    GlobalModelConfig.current_organization_id = organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Notification, @notification
    fixture_notification = notifications(:administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed)
    assert_equal fixture_notification.status, @notification.status
    assert_equal fixture_notification.notes, @notification.notes
    assert_equal fixture_notification.confirmation_hash,
      @notification.confirmation_hash
    assert_equal fixture_notification.confirmation_date,
      @notification.confirmation_date
    assert_equal fixture_notification.user_id, @notification.user_id
  end

  # Prueba la creación de una notificación
  test 'create' do
    assert_difference 'Notification.count' do
      @notification = Notification.create(
        :user_id => users(:administrator_user).id,
        :notes => 'New notes'
      )
    end

    assert !@notification.notified?
    assert_equal @notification.notes, 'New notes'
  end

  # Prueba de actualización de una notificacion
  test 'update' do
    new_confirmation_hash = UUIDTools::UUID.random_create.to_s

    assert @notification.update(
      :confirmation_hash => new_confirmation_hash, :notes => 'Updated notes'),
      @notification.errors.full_messages.join('; ')
    assert_equal new_confirmation_hash, @notification.confirmation_hash
    assert_equal 'Updated notes', @notification.notes
  end

  # Prueba de eliminación de notificaciones
  test 'delete' do
    assert_difference('Notification.count', -1) { @notification.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @notification.confirmation_hash = '   '
    @notification.user_id = nil
    assert @notification.invalid?
    assert_equal 2, @notification.errors.count
    assert_equal [error_message_from_model(@notification, :confirmation_hash,
      :blank)], @notification.errors[:confirmation_hash]
    assert_equal [error_message_from_model(@notification, :user_id, :blank)],
      @notification.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @notification.user_id = '12.3'
    @notification.status = '_12'
    @notification.user_who_confirm_id = 'x123'
    @notification.confirmation_date = '12/34/34'
    assert @notification.invalid?
    assert_equal 4, @notification.errors.count
    assert_equal [error_message_from_model(@notification, :user_id,
      :not_an_integer)], @notification.errors[:user_id]
    assert_equal [error_message_from_model(@notification, :status,
      :not_a_number)], @notification.errors[:status]
    assert_equal [error_message_from_model(@notification, :user_who_confirm_id,
      :not_a_number)], @notification.errors[:user_who_confirm_id]
    assert_equal [error_message_from_model(@notification, :confirmation_date,
      :invalid_datetime)], @notification.errors[:confirmation_date]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @notification.confirmation_hash = 'abc' * 100
    assert @notification.invalid?
    assert_equal 1, @notification.errors.count
    assert_equal [error_message_from_model(@notification, :confirmation_hash,
      :too_long, :count => 255)], @notification.errors[:confirmation_hash]
  end

  test 'dynamic functions' do
    Notification::STATUS.each do |status, value|
      @notification.status = value
      assert @notification.send(:"#{status}?")

      Notification::STATUS.each do |k, v|
        unless k == status
          @notification.status = v
          assert !@notification.send(:"#{status}?")
        end
      end
    end
  end

  test 'notify function' do
    @notification = Notification.find(notifications(
        :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id)
    pendings = @notification.findings.select(&:unconfirmed?)
    confirmed = @notification.findings.select(&:confirmed?)

    assert confirmed.empty?
    assert pendings.empty?
    assert_nil @notification.confirmation_date
    assert !@notification.user.can_act_as_audited?
    assert @notification.notify!

    pendings = @notification.findings.reload.select(&:unconfirmed?)
    confirmed = @notification.findings.reload.select(&:confirmed?)

    # No se confirma porque no es un auditado (es bare_user)
    assert confirmed.empty?
    assert pendings.empty?
    assert @notification.confirmed?
    assert_not_nil @notification.confirmation_date

    @notification = Notification.find(notifications(
        :audited_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id)
    pendings = @notification.findings.select(&:unconfirmed?)
    confirmed = @notification.findings.select(&:confirmed?)
    notifications_for_not_audit_users = @notification.findings.map do |f|
      f.notifications.select do |n|
        !n.user.can_act_as_audited? && !n.confirmed?
      end
    end.flatten.compact.uniq

    assert confirmed.empty?
    assert !pendings.empty?
    assert !notifications_for_not_audit_users.empty?
    assert @notification.user.can_act_as_audited?
    assert_nil @notification.confirmation_date
    assert @notification.notify!
    assert @notification.confirmed?
    assert_not_nil @notification.confirmation_date

    pendings = @notification.findings.reload.select(&:unconfirmed?)
    confirmed = @notification.findings.reload.select(&:confirmed?)

    # Se confirma porque es un auditado (es audited_user)
    assert !confirmed.empty?
    assert pendings.empty?
    assert notifications_for_not_audit_users.all? { |n| n.reload.confirmed? }

    # Rechazar la notificación
    assert @notification.notify!(false)
    assert @notification.rejected?
  end
end
