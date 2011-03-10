require 'test_helper'

# Clase para probar el modelo "FindingUserAssignment"
class FindingUserAssignmentTest < ActiveSupport::TestCase
  fixtures :finding_user_assignments

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding_user_assignment = FindingUserAssignment.find(
      finding_user_assignments(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_administrator_user).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_assignment = finding_user_assignments(
      :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_administrator_user)
    assert_kind_of FindingUserAssignment, @finding_user_assignment
    assert_equal fixture_assignment.user_id, @finding_user_assignment.user_id
    assert_equal fixture_assignment.finding_id,
      @finding_user_assignment.finding_id
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
    old_updated_at = @finding_user_assignment.updated_at

    assert @finding_user_assignment.touch,
      @finding_user_assignment.errors.full_messages.join('; ')
    @finding_user_assignment.reload

    assert_not_equal old_updated_at,
      @finding_user_assignment.updated_at
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
    assert_equal 1, @finding_user_assignment.errors.count
    assert_equal [error_message_from_model(
      @finding_user_assignment, :user_id, :blank)],
      @finding_user_assignment.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @finding_user_assignment.user_id = '123-'
    assert @finding_user_assignment.invalid?
    assert_equal 1, @finding_user_assignment.errors.count
    assert_equal [error_message_from_model(
      @finding_user_assignment, :user_id, :not_a_number)],
      @finding_user_assignment.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated user' do
    finding = @finding_user_assignment.finding
    # Para que ARel cargue la relación
    finding.finding_user_assignments.map(&:user_id)
    finding_user_assignment = finding.finding_user_assignments.build(
      :user_id => @finding_user_assignment.user_id
    )
    finding_user_assignment.finding = finding
    finding_user_assignment.invalid?
    assert finding_user_assignment.invalid?
    assert_equal 1, finding_user_assignment.errors.count
    assert_equal [error_message_from_model(finding_user_assignment, :user_id,
        :taken)], finding_user_assignment.errors[:user_id]
  end

  test 'validates process owner' do
    @finding_user_assignment.process_owner = true

    assert @finding_user_assignment.invalid?
    assert_equal 1, @finding_user_assignment.errors.size
    assert_equal [error_message_from_model(@finding_user_assignment,
        :process_owner, :invalid)],
      @finding_user_assignment.errors[:process_owner]
  end
end
