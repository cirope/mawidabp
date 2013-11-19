require 'test_helper'

# Clase para probar el modelo "ConclusionDraftReview"
class ConclusionDraftReviewTest < ActiveSupport::TestCase
  fixtures :conclusion_reviews

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_current_draft_review).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ConclusionDraftReview, @conclusion_review
    fixture_conclusion_review =
      conclusion_reviews(:conclusion_current_draft_review)
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

  # Prueba la creación de un informe borrador
  test 'create' do
    assert_difference 'ConclusionDraftReview.count' do
      @conclusion_review = ConclusionDraftReview.create(
        :review => reviews(:review_without_conclusion),
        :issue_date => Date.today,
        :close_date => 2.days.from_now.to_date,
        :applied_procedures => 'New applied procedures',
        :conclusion => 'New conclusion'
      )

      # Asegurarse que le asigna el tipo correcto
      assert_equal 'ConclusionDraftReview', @conclusion_review.type
    end
  end

  # Prueba de actualización de un informe borrador
  test 'update' do
    assert @conclusion_review.update(
      :applied_procedures => 'Updated applied procedures'),
      @conclusion_review.errors.full_messages.join('; ')
    @conclusion_review.reload
    assert_equal 'Updated applied procedures',
      @conclusion_review.applied_procedures
  end

  # Prueba de eliminación de informes borradores
  test 'destroy' do
    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_difference 'ConclusionDraftReview.count', -1 do
      conclusion_review.destroy
    end
  end

  # Prueba de eliminación de informes borradores
  test 'can not be destroyed' do
    assert_no_difference 'ConclusionDraftReview.count' do
      @conclusion_review.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @conclusion_review.issue_date = nil
    @conclusion_review.review_id = nil
    @conclusion_review.applied_procedures = '   '

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :issue_date, :blank
    assert_error @conclusion_review, :review_id, :blank
    assert_error @conclusion_review, :applied_procedures, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @conclusion_review.issue_date = '13/13/13'

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :issue_date, :blank
  end

  test 'validates unique attributes' do
    @conclusion_review.review_id =
      conclusion_reviews(:conclusion_past_draft_review).review_id

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :review_id, :taken
  end

  test 'validates force approved review' do
    @conclusion_review = conclusion_reviews(
      :conclusion_approved_with_conclusion_draft_review
    )
    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?

    @conclusion_review.review.update_attribute :survey, nil

    assert @conclusion_review.check_for_approval
    assert !@conclusion_review.approved?

    # Ahora se elije saltar esta validación
    @conclusion_review.force_approval = true

    assert @conclusion_review.check_for_approval
    assert @conclusion_review.approved?
    assert @conclusion_review.save

    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?
  end
end
