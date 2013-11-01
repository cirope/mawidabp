require 'test_helper'

# Clase para probar el modelo "FindingReviewAssignment"
class FindingReviewAssignmentTest < ActiveSupport::TestCase
  fixtures :finding_review_assignments

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding_review_assignment = FindingReviewAssignment.find(
      finding_review_assignments(
        :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_assignment = finding_review_assignments(
      :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented)
    assert_kind_of FindingReviewAssignment, @finding_review_assignment
    assert_equal fixture_assignment.review_id,
      @finding_review_assignment.review_id
    assert_equal fixture_assignment.finding_id,
      @finding_review_assignment.finding_id
  end

  # Prueba la creación de una asignación de usuario
  test 'create' do
    assert_difference 'FindingReviewAssignment.count' do
      @finding_review_assignment =
        FindingReviewAssignment.create(
          :review => reviews(:review_without_conclusion),
          :finding => findings(
            :bcra_A4609_data_proccessing_impact_analisys_weakness)
        )
    end
  end

  # Prueba de actualización de una asignación de usuario
  test 'update' do
    old_updated_at = @finding_review_assignment.updated_at

    assert @finding_review_assignment.touch,
      @finding_review_assignment.errors.full_messages.join('; ')
    @finding_review_assignment.reload

    assert_not_equal old_updated_at,
      @finding_review_assignment.updated_at
  end

  # Prueba de eliminación de una asignación de usuario
  test 'delete' do
    finding_review_assignment = FindingReviewAssignment.find(finding_review_assignments(
        :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    assert_difference 'FindingReviewAssignment.count', -1 do
      finding_review_assignment.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank atrtributes' do
    @finding_review_assignment.finding_id = nil

    assert @finding_review_assignment.invalid?
    assert_error @finding_review_assignment, :finding_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @finding_review_assignment.finding_id = '123-'

    assert @finding_review_assignment.invalid?
    assert_error @finding_review_assignment, :finding_id, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated review' do
    review = @finding_review_assignment.review
    # Para que ARel cargue la relación
    review.finding_review_assignments.map(&:finding_id)
    finding_review_assignment = review.finding_review_assignments.build(
      :finding_id => @finding_review_assignment.finding_id
    )
    finding_review_assignment.review = review

    assert finding_review_assignment.invalid?
    assert_error finding_review_assignment, :finding_id, :taken
  end
end
