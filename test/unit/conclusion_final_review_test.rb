require 'test_helper'

# Clase para probar el modelo "ConclusionFinalReview"
class ConclusionFinalReviewTest < ActiveSupport::TestCase
  fixtures :conclusion_reviews

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_current_final_review).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ConclusionFinalReview, @conclusion_review
    fixture_conclusion_review =
      conclusion_reviews(:conclusion_current_final_review)
    assert_equal fixture_conclusion_review.type, @conclusion_review.type
    assert_equal fixture_conclusion_review.review_id,
      @conclusion_review.review_id
    assert_equal fixture_conclusion_review.issue_date,
      @conclusion_review.issue_date
    assert_equal fixture_conclusion_review.applied_procedures,
      @conclusion_review.applied_procedures
    assert_equal fixture_conclusion_review.conclusion,
      @conclusion_review.conclusion
  end

  # Prueba la creación de un informe final
  test 'create' do
    review = Review.find reviews(:review_with_conclusion).id
    findings_count = (review.weaknesses + review.oportunities).size

    assert findings_count > 0

    assert_difference 'ConclusionFinalReview.count' do
      assert_difference 'Finding.count', findings_count do
        @conclusion_review = ConclusionFinalReview.new({
          :review => review,
          :issue_date => Time.now.to_date,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => 'New conclusion'
        }, false)

        assert @conclusion_review.save, @conclusion_review.errors.full_messages.join('; ')
        # Asegurarse que le asigna el tipo correcto
        assert_equal 'ConclusionFinalReview', @conclusion_review.type
      end
    end

    final_findings_count =
      (review.final_weaknesses + review.final_oportunities).size

    assert_equal findings_count, final_findings_count
    assert_not_equal 0, Finding.finals(true).count
    assert Finding.finals(true).all? { |f| f.parent }
  end

  # Prueba la creación de un informe final con observaciones reiteradas
  test 'create with repeated findings' do
    review = Review.find reviews(:review_with_conclusion).id
    findings = review.weaknesses + review.oportunities
    repeated_id = findings(
      :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id

    assert findings.size > 0

    assert_difference 'Finding.repeated.count' do
      assert review.update_attributes(
        :finding_review_assignments_attributes => {
          :new_1 => {:finding_id => repeated_id}
        }
      )
      assert findings.detect(&:being_implemented?).update_attributes(
        :repeated_of_id => repeated_id
      )
    end

    assert_difference 'ConclusionFinalReview.count' do
      assert_difference 'Finding.count', findings.size do
        @conclusion_review = ConclusionFinalReview.new({
          :review => review,
          :issue_date => Time.now.to_date,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => 'New conclusion'
        }, false)

        assert @conclusion_review.save, @conclusion_review.errors.full_messages.join('; ')
        # Asegurarse que le asigna el tipo correcto
        assert_equal 'ConclusionFinalReview', @conclusion_review.type
      end
    end

    final_findings_count =
      (review.final_weaknesses + review.final_oportunities).size

    assert_equal findings.size, final_findings_count
    assert_not_equal 0, Finding.finals(true).count
    assert Finding.finals(true).all? { |f| f.parent }
  end

  # Prueba de actualización de un informe final
  test 'update' do
    assert @conclusion_review.update_attributes(
      :applied_procedures => 'Updated applied procedures'),
      @conclusion_review.errors.full_messages.join('; ')
    @conclusion_review.reload
    # No se puede modificar ningún dato
    assert_not_equal 'Updated applied procedures',
      @conclusion_review.applied_procedures
  end

  # Prueba de eliminación de informes finales
  test 'destroy' do
    assert_no_difference 'ConclusionFinalReview.count' do
      @conclusion_review.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @conclusion_review.issue_date = nil
    @conclusion_review.review_id = nil
    @conclusion_review.applied_procedures = '   '
    @conclusion_review.conclusion = '   '
    assert @conclusion_review.invalid?
    assert_equal 4, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :issue_date,
      :blank)], @conclusion_review.errors[:issue_date]
    assert_equal [error_message_from_model(@conclusion_review, :review_id,
      :blank)], @conclusion_review.errors[:review_id]
    assert_equal [error_message_from_model(@conclusion_review,
      :applied_procedures, :blank)],
      @conclusion_review.errors[:applied_procedures]
    assert_equal [error_message_from_model(@conclusion_review, :conclusion,
      :blank)], @conclusion_review.errors[:conclusion]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @conclusion_review.review_id =
      conclusion_reviews(:conclusion_past_final_review).review_id
    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :review_id,
      :taken)], @conclusion_review.errors[:review_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @conclusion_review.issue_date = '13/13/13'
    assert @conclusion_review.invalid?
    assert_equal 2, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :issue_date,
      :blank), error_message_from_model(@conclusion_review, :issue_date,
      :invalid_date)].sort, @conclusion_review.errors[:issue_date].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates approved review' do
    @conclusion_review.review.conclusion_draft_review.approved = false
    
    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :review_id,
      :invalid)], @conclusion_review.errors[:review_id]
  end

  test 'validates force approved review' do
    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?
    
    conclusion_draft_review = @conclusion_review.conclusion_draft_review

    assert conclusion_draft_review.approved?

    @conclusion_review.review.update_attribute :survey, nil

    assert conclusion_draft_review.check_for_approval
    assert !conclusion_draft_review.approved?

    # Ahora se elije saltar esta validación
    conclusion_draft_review.force_approval = true

    assert conclusion_draft_review.check_for_approval
    assert conclusion_draft_review.approved?
    assert conclusion_draft_review.save

    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates invalid draft review' do
    @conclusion_review.review = reviews(:review_without_conclusion)
    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :review_id,
      :without_draft)], @conclusion_review.errors[:review_id]
  end

  test 'duplicate review findings' do
    review = Review.find reviews(:review_with_conclusion).id
    findings = review.weaknesses + review.oportunities
    final_findings = review.final_weaknesses + review.final_oportunities
    work_papers_count = findings.inject(0) { |acc, f| acc + f.work_papers.size }
    final_work_papers_count = final_findings.inject(0) do |acc, f|
      acc + f.work_papers.size
    end

    assert work_papers_count > 0
    assert_equal 0, final_work_papers_count

    assert_difference 'ConclusionFinalReview.count' do
      @conclusion_review = ConclusionFinalReview.new({
        :review => review,
        :issue_date => Time.now.to_date,
        :close_date => 2.days.from_now.to_date,
        :applied_procedures => 'New applied procedures',
        :conclusion => 'New conclusion'
      }, false)

      assert @conclusion_review.save,
        @conclusion_review.errors.full_messages.join('; ')
    end

    findings = review.weaknesses(true) + review.oportunities(true)
    work_papers_count = findings.inject(0) { |acc, f| acc + f.work_papers.size }
    final_findings = review.reload.final_weaknesses(true) +
      review.reload.final_oportunities(true)
    final_work_papers_count = final_findings.inject(0) do |acc, f|
      acc + f.work_papers.size
    end

    assert final_work_papers_count > 0
    assert_equal final_work_papers_count, work_papers_count
    assert_not_nil @conclusion_review.issue_date
    assert(findings.all? do |f|
      f.origination_date == @conclusion_review.issue_date
    end)
    assert(final_findings.all? do |f|
      f.origination_date == @conclusion_review.issue_date
    end)
  end
end