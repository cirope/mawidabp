require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  fixtures :notifications, :users, :findings

  def setup
    set_organization

    @notification = 
      notifications :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed
  end

  test 'create' do
    assert_difference 'Notification.count' do
      @notification = Notification.create(
        user_id: users(:administrator_user).id,
        notes:  'New notes'
      )
    end

    assert !@notification.notified?
    assert_equal @notification.notes, 'New notes'
  end

  test 'update' do
    new_confirmation_hash = SecureRandom.urlsafe_base64

    assert @notification.update(
      confirmation_hash: new_confirmation_hash, notes: 'Updated notes'),
      @notification.errors.full_messages.join('; ')
    assert_equal new_confirmation_hash, @notification.confirmation_hash
    assert_equal 'Updated notes', @notification.notes
  end

  test 'delete' do
    assert_difference('Notification.count', -1) { @notification.destroy }
  end

  test 'validates blank attributes' do
    @notification.confirmation_hash = '   '
    @notification.user = nil

    assert @notification.invalid?
    assert_error @notification, :confirmation_hash, :blank
    assert_error @notification, :user, :blank
  end

  test 'validates formatted attributes' do
    @notification.confirmation_date = '12/34/34'

    assert @notification.invalid?
    assert_error @notification, :confirmation_date, :invalid_datetime
  end

  test 'validates included attributes' do
    @notification.status = Notification::STATUS.values.last + 1

    assert @notification.invalid?
    assert_error @notification, :status, :inclusion
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @notification.confirmation_hash = 'abc' * 100

    assert @notification.invalid?
    assert_error @notification, :confirmation_hash, :too_long, count: 255
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
