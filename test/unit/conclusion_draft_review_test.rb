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
        :issue_date => Time.now.to_date,
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
    assert @conclusion_review.update_attributes(
      :applied_procedures => 'Updated applied procedures'),
      @conclusion_review.errors.full_messages.join('; ')
    @conclusion_review.reload
    assert_equal 'Updated applied procedures',
      @conclusion_review.applied_procedures
  end

  # Prueba de eliminación de informes borradores
  test 'destroy' do
    assert_no_difference 'ConclusionDraftReview.count' do
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
    assert_equal error_message_from_model(@conclusion_review, :issue_date,
      :blank), @conclusion_review.errors.on(:issue_date)
    assert_equal error_message_from_model(@conclusion_review, :review_id,
      :blank), @conclusion_review.errors.on(:review_id)
    assert_equal error_message_from_model(@conclusion_review,
      :applied_procedures, :blank),
      @conclusion_review.errors.on(:applied_procedures)
    assert_equal error_message_from_model(@conclusion_review, :conclusion,
      :blank), @conclusion_review.errors.on(:conclusion)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @conclusion_review.issue_date = '13/13/13'
    assert @conclusion_review.invalid?
    assert_equal 2, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :issue_date,
      :blank), error_message_from_model(@conclusion_review, :issue_date,
      :invalid_date)].sort, @conclusion_review.errors.on(:issue_date).sort
  end

  test 'validates unique attributes' do
    @conclusion_review.review_id =
      conclusion_reviews(:conclusion_past_draft_review).review_id
    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal error_message_from_model(@conclusion_review, :review_id,
      :taken), @conclusion_review.errors.on(:review_id)
  end

  test 'check for approval with rejected notifications' do
    assert @conclusion_review.check_for_approval
    assert @conclusion_review.approved?

    @conclusion_review.notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert @conclusion_review.reload.check_for_approval
    assert !@conclusion_review.approved?

    assert @conclusion_review.notifications(true).first.notify!(false)

    assert @conclusion_review.check_for_approval
    assert !@conclusion_review.approved?

    # Ahora se elije saltar esta validación
    @conclusion_review.force_approval = true

    assert @conclusion_review.check_for_approval
    assert @conclusion_review.approved?

    @conclusion_review.force_approval = false
    
    assert @conclusion_review.check_for_approval
    assert !@conclusion_review.approved?

    # Ahora el mismo usuario crea confirma una nueva notificación
    @conclusion_review.notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert @conclusion_review.notifications(true).first.notify!(true)

    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?
  end
end