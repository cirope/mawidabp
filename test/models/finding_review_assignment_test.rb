require 'test_helper'

class FindingReviewAssignmentTest < ActiveSupport::TestCase
  setup do
    @finding_review_assignment =
      finding_review_assignments :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented
  end

  test 'create' do
    assert_difference 'FindingReviewAssignment.count' do
      @finding_review_assignment = FindingReviewAssignment.create!(
        review:  reviews(:review_without_conclusion),
        finding: findings(:bcra_A4609_data_proccessing_impact_analisys_weakness)
      )
    end
  end

  test 'update' do
    old_updated_at = @finding_review_assignment.updated_at

    assert @finding_review_assignment.touch,
      @finding_review_assignment.errors.full_messages.join('; ')
    @finding_review_assignment.reload

    assert_not_equal old_updated_at, @finding_review_assignment.updated_at
  end

  test 'destroy' do
    finding_review_assignment =
      finding_review_assignments :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented

    assert_difference 'FindingReviewAssignment.count', -1 do
      finding_review_assignment.destroy
    end
  end

  test 'destroy gets cancelled if repeated' do
    finding_review_assignment =
      finding_review_assignments :review_without_conclusion_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented

    finding_review_assignment.finding.update! state: Finding::STATUS[:repeated]

    assert_no_difference 'FindingReviewAssignment.count' do
      finding_review_assignment.destroy
    end
  end

  test 'validates blank atrtributes' do
    @finding_review_assignment.finding_id = nil

    assert @finding_review_assignment.invalid?
    assert_error @finding_review_assignment, :finding_id, :blank
  end

  test 'validates duplicated review' do
    review = @finding_review_assignment.review
    # Para que ARel cargue la relación
    review.finding_review_assignments.map(&:finding_id)
    finding_review_assignment = review.finding_review_assignments.build(
      finding_id: @finding_review_assignment.finding_id
    )
    finding_review_assignment.review = review

    assert finding_review_assignment.invalid?
    assert_error finding_review_assignment, :finding_id, :taken
  end
end
