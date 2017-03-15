require 'test_helper'

# Clase para probar el modelo "FindingUserAssignment"
class FindingUserAssignmentTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  fixtures :finding_user_assignments

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    set_organization

    @finding_user_assignment = FindingUserAssignment.find(
      finding_user_assignments(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_manager_user).id)
  end

  # Prueba la creación de una asignación de usuario
  test 'create' do
    assert_difference 'FindingUserAssignment.count' do
      @finding_user_assignment =
        FindingUserAssignment.create(
          :user => users(:expired_user),
          :finding_id => findings(
            :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id
        )
    end
  end

  # Prueba de actualización de una asignación de usuario
  test 'update' do
    assert_enqueued_emails 1 do
      assert @finding_user_assignment.update!(
        :user_id => users(:supervisor_user).id
      )
    end

    assert_no_enqueued_emails do
      assert @finding_user_assignment.update!(
        :responsible_auditor => !@finding_user_assignment.responsible_auditor
      )
    end
  end

  # Prueba de eliminación de una asignación de usuario
  test 'delete' do
    finding_user_assignment = FindingUserAssignment.find(finding_user_assignments(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_administrator_user).id)

    assert_difference 'FindingUserAssignment.count', -1 do
      finding_user_assignment.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank atrtributes' do
    @finding_user_assignment.user_id = nil

    assert @finding_user_assignment.invalid?
    assert_error @finding_user_assignment, :user_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @finding_user_assignment.user_id = '123-'

    assert @finding_user_assignment.invalid?
    assert_error @finding_user_assignment, :user_id, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated user' do
    finding = @finding_user_assignment.finding
    # Para que ARel cargue la relación
    finding.finding_user_assignments.map(&:user_id)
    finding_user_assignment = finding.finding_user_assignments.build(
      :user_id => @finding_user_assignment.user_id
    )
    finding_user_assignment.raw_finding = finding

    assert finding_user_assignment.invalid?
    assert_error finding_user_assignment, :user_id, :taken
  end

  test 'validates process owner' do
    @finding_user_assignment.process_owner = true

    assert @finding_user_assignment.invalid?
    assert_error @finding_user_assignment, :process_owner, :invalid
  end
end
