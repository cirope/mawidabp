require 'test_helper'

# Clase para probar el modelo "ReviewUserAssignment"
class ReviewUserAssignmentTest < ActiveSupport::TestCase
  fixtures :review_user_assignments

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @review_user_assignment = ReviewUserAssignment.find(review_user_assignments(
        :review_with_conclusion_auditor).id)

    set_organization
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_assignment = review_user_assignments :review_with_conclusion_auditor
    assert_kind_of ReviewUserAssignment, @review_user_assignment
    assert_equal fixture_assignment.assignment_type,
      @review_user_assignment.assignment_type
    assert_equal fixture_assignment.user_id, @review_user_assignment.user_id
    assert_equal fixture_assignment.review_id, @review_user_assignment.review_id
  end

  # Prueba la creación de una asignación de usuario
  test 'create' do
    assert_difference 'ReviewUserAssignment.count' do
      @review_user_assignment =
        ReviewUserAssignment.create(
        assignment_type:  ReviewUserAssignment::TYPES[:auditor],
        user: users(:expired),
        review_id: reviews(:review_with_conclusion).id
      )
    end
  end

  # Prueba de actualización de una asignación de usuario
  test 'update' do
    old_updated_at = @review_user_assignment.updated_at

    assert @review_user_assignment.touch,
      @review_user_assignment.errors.full_messages.join('; ')
    @review_user_assignment.reload

    assert_not_equal old_updated_at,
      @review_user_assignment.updated_at
  end

  # Prueba de eliminación de una asignación de usuario
  test 'delete' do
    review_user_assignment = ReviewUserAssignment.find(review_user_assignments(
        :review_with_conclusion_auditor).id)

    assert_difference 'ReviewUserAssignment.count', -1 do
      review_user_assignment.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank atrtributes' do
    @review_user_assignment.assignment_type = nil
    @review_user_assignment.user_id = nil

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :assignment_type, :blank
    assert_error @review_user_assignment, :user_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @review_user_assignment.assignment_type = 'aaa'
    @review_user_assignment.user_id = '123-'
    @review_user_assignment.review_id = '12.3'

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :assignment_type, :not_a_number
    assert_error @review_user_assignment, :user_id, :not_a_number
    assert_error @review_user_assignment, :review_id, :not_an_integer
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @review_user_assignment.assignment_type =
      ReviewUserAssignment::TYPES.values.sort.last.next

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :assignment_type, :inclusion
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates user is a supervisor and manager attributes' do
    @review_user_assignment.assignment_type =
      ReviewUserAssignment::TYPES[:supervisor]

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :user_id, :invalid

    @review_user_assignment.assignment_type =
      ReviewUserAssignment::TYPES[:manager]

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :user_id, :invalid
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated user' do
    review = @review_user_assignment.review
    # Para que ARel cargue la relación
    review.review_user_assignments.map(&:user_id)
    review.review_user_assignments.build(
      @review_user_assignment.attributes.merge('id' => nil))

    assert @review_user_assignment.invalid?
    assert_error @review_user_assignment, :user_id, :taken
  end

  test 'user reassignment' do
    review_user_assignment = ReviewUserAssignment.find(
      review_user_assignments(:review_with_conclusion_audited).id)
    old_user = User.find review_user_assignment.user_id
    review_user_assignment.user_id = users(:audited_second).id
    original_finding_ids = old_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).map(&:id).sort

    assert !old_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert review_user_assignment.user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'Notification.count' do
        assert review_user_assignment.save
      end
    end

    assert old_user.reload.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert !review_user_assignment.user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert_equal original_finding_ids,
      review_user_assignment.user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).map(&:id).sort
  end

  test 'try a user reassignment with an invalid result' do
    review_user_assignment = ReviewUserAssignment.find(
      review_user_assignments(:review_with_conclusion_audited).id)
    old_user = User.find review_user_assignment.user_id
    new_user = User.find users(:administrator_second).id
    review_user_assignment.user = new_user
    original_finding_ids = old_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).map(&:id).sort

    assert !old_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert new_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'Notification.count' do
        assert !review_user_assignment.save
      end
    end

    assert !old_user.reload.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert new_user.reload.findings.all_for_reallocation_with_review(
      review_user_assignment.review).blank?
    assert_equal original_finding_ids,
      old_user.findings.all_for_reallocation_with_review(
      review_user_assignment.review).map(&:id).sort
  end

  test 'delete user in all review findings' do
    review_user_assignment = review_user_assignments(:review_with_conclusion_auditor)
    findings = review_user_assignment.user.findings.
      all_for_reallocation_with_review(review_user_assignment.review)

    assert findings.present?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ReviewUserAssignment.count', -1 do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        review_user_assignment.destroy
      end
    end

    assert findings.reload.blank?
  end

  test 'delete the last audited user in a review with pending findings' do
    review_user_assignment = review_user_assignments :review_with_conclusion_audited
    review = review_user_assignment.review
    user = review_user_assignment.user
    findings = user.findings.all_for_reallocation_with_review(review)

    assert_not_equal 0, findings.size

    findings.each do |finding|
      finding.finding_user_assignments.each do |fua|
        Finding.transaction do
          fua.destroy! unless fua.user_id == user.id

          raise ActiveRecord::Rollback unless finding.reload.valid?
        end
      end
    end

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      review_user_assignment.destroy!
    end

    assert_equal findings.size, findings.reload.size
  end

  test 'can be modified' do
    uneditable_review_user_assignment = ReviewUserAssignment.find(
      review_user_assignments(:current_review_auditor).id)

    @review_user_assignment.user_id = users(:administrator).id

    assert !@review_user_assignment.is_in_a_final_review?
    assert @review_user_assignment.can_be_modified?

    assert uneditable_review_user_assignment.is_in_a_final_review?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_review_user_assignment.can_be_modified?

    uneditable_review_user_assignment.user_id = users(:administrator).id

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_review_user_assignment.can_be_modified?
    assert !uneditable_review_user_assignment.save

    assert_no_difference 'ReviewUserAssignment.count' do
      uneditable_review_user_assignment.destroy
    end
  end

  test 'in audit team' do
    assert @review_user_assignment.in_audit_team?

    @review_user_assignment.assignment_type = ReviewUserAssignment::TYPES[:viewer]

    refute @review_user_assignment.in_audit_team?
  end
end
