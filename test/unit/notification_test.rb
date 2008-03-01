require 'test_helper'

# Clase para probar el modelo "Notification"
class NotificationTest < ActiveSupport::TestCase
  fixtures :notifications, :users, :findings

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @notification = Notification.find(
      notifications(:administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_notify_confirmed).id)
    GlobalModelConfig.current_organization_id = organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Notification, @notification
    fixture_notification = notifications(:administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_notify_confirmed)
    assert_equal fixture_notification.status, @notification.status
    assert_equal fixture_notification.notes, @notification.notes
    assert_equal fixture_notification.confirmation_hash,
      @notification.confirmation_hash
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

    assert @notification.update_attributes(
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
    assert_equal error_message_from_model(@notification, :confirmation_hash,
      :blank), @notification.errors.on(:confirmation_hash)
    assert_equal error_message_from_model(@notification, :user_id, :blank),
      @notification.errors.on(:user_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @notification.user_id = '12.3'
    @notification.status = '_12'
    @notification.user_who_confirm_id = 'x123'
    assert @notification.invalid?
    assert_equal 3, @notification.errors.count
    assert_equal error_message_from_model(@notification, :user_id,
      :not_a_number), @notification.errors.on(:user_id)
    assert_equal error_message_from_model(@notification, :status,
      :not_a_number), @notification.errors.on(:status)
    assert_equal error_message_from_model(@notification, :user_who_confirm_id,
      :not_a_number), @notification.errors.on(:user_who_confirm_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @notification.confirmation_hash = 'abc' * 100
    assert @notification.invalid?
    assert_equal 1, @notification.errors.count
    assert_equal error_message_from_model(@notification, :confirmation_hash,
      :too_long, :count => 255), @notification.errors.on(:confirmation_hash)
  end

  test 'dynamic functions' do
    Notification::STATUSES.each do |status, value|
      @notification.status = value
      assert @notification.send("#{status}?".to_sym)

      Notification::STATUSES.each do |k, v|
        unless k == status
          @notification.status = v
          assert !@notification.send("#{status}?".to_sym)
        end
      end
    end
  end

  test 'notify function' do
    @notification = Notification.find(notifications(
        :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id)
    pendings = @notification.findings.select do |f|
      f.notifications.any? { |n| !n.notified? }
    end

    confirmed = @notification.findings.select { |f| f.confirmed? }

    assert confirmed.empty?
    assert !pendings.empty?
    assert @notification.notify!

    pendings = @notification.findings(true).select do |f|
      f.notifications(true).any? { |n| !n.notified? }
    end
    confirmed = @notification.findings(true).select { |f| f.confirmed? }

    # No se confirma porque no es un auditado (es bare_user)
    assert confirmed.empty?
    assert !pendings.empty?

    @notification = Notification.find(notifications(
        :audited_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id)
    pendings = @notification.findings.select do |f|
      f.notifications.any? { |n| !n.notified? }
    end

    confirmed = @notification.findings.select { |f| f.confirmed? }

    assert confirmed.empty?
    assert !pendings.empty?
    assert @notification.notify!
    assert @notification.confirmed?

    pendings = @notification.findings(true).select do |f|
      f.notifications(true).any? { |n| !n.notified? }
    end
    confirmed = @notification.findings(true).select { |f| f.confirmed? }

    # Se confirma porque es un auditado (es audited_user)
    assert !confirmed.empty?
    assert pendings.empty?

    # Rechazar la notificación
    assert @notification.notify!(false)
    assert @notification.rejected?
  end
end