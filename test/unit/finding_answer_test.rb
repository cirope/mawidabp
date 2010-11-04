require 'test_helper'

# Clase para probar el modelo "FindingAnswer"
class FindingAnswerTest < ActiveSupport::TestCase
  fixtures :finding_answers, :findings, :users

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding_answer = FindingAnswer.find finding_answers(
      :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity_auditor_answer).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_finding_answer = finding_answers(
      :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity_auditor_answer)
    assert_kind_of FindingAnswer, @finding_answer
    assert_equal fixture_finding_answer.answer, @finding_answer.answer
    assert_equal fixture_finding_answer.auditor_comments,
      @finding_answer.auditor_comments
    assert_equal fixture_finding_answer.answer_type, @finding_answer.answer_type
    assert_equal fixture_finding_answer.finding_id, @finding_answer.finding_id
    assert_equal fixture_finding_answer.user_id, @finding_answer.user_id
    assert_equal fixture_finding_answer.file_model_id,
      @finding_answer.file_model_id
  end

  # Prueba la creación de una respuesta a una observación
  test 'create without notification' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          :answer => 'New answer',
          :auditor_comments => 'New auditor comments',
          :answer_type =>
            get_test_parameter(:admin_finding_answers_types).first[1],
          :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          :user => users(:administrator_user),
          :file_model => file_models(:text_file)
        )
      end
    end
  end

  # Prueba la creación de una respuesta a una observación
  test 'create with notification' do
    counts_array = ['FindingAnswer.count', 'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      @finding_answer = FindingAnswer.create(
        :answer => 'New answer',
        :auditor_comments => 'New auditor comments',
        :answer_type =>
          get_test_parameter(:admin_finding_answers_types).first[1],
        :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
        :user => users(:administrator_user),
        :file_model => file_models(:text_file),
        :notify_users => true
      )
    end
  end

  # Prueba de actualización de una respuesta a una observación
  test 'update' do
    assert @finding_answer.update_attributes(:answer => 'New answer'),
      @finding_answer.errors.full_messages.join('; ')
    @finding_answer.reload
    # No se puede cambiar una respuesta
    assert_not_equal 'New answer', @finding_answer.answer
  end

  # Prueba de eliminación de respuestas a observaciones
  test 'delete' do
    assert_difference('FindingAnswer.count', -1) { @finding_answer.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @finding_answer.answer = '      '
    @finding_answer.finding_id = nil
    @finding_answer.answer_type = nil
    assert @finding_answer.invalid?
    assert_equal 3, @finding_answer.errors.count
    assert_equal [error_message_from_model(@finding_answer, :answer, :blank)],
      @finding_answer.errors[:answer]
    assert_equal [error_message_from_model(@finding_answer, :finding_id,
        :blank)], @finding_answer.errors[:finding_id]
    assert_equal [error_message_from_model(@finding_answer, :answer_type,
      :blank)], @finding_answer.errors[:answer_type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @finding_answer.finding_id = '?nil'
    @finding_answer.user_id = '?123'
    @finding_answer.file_model_id = 'incorrect'
    @finding_answer.answer_type = '12.3'
    assert @finding_answer.invalid?
    assert_equal 4, @finding_answer.errors.count
    assert_equal [error_message_from_model(@finding_answer, :finding_id,
      :not_a_number)], @finding_answer.errors[:finding_id]
    assert_equal [error_message_from_model(@finding_answer, :user_id,
      :not_a_number)], @finding_answer.errors[:user_id]
    assert_equal [error_message_from_model(@finding_answer, :file_model_id,
      :not_a_number)], @finding_answer.errors[:file_model_id]
    assert_equal [error_message_from_model(@finding_answer, :answer_type,
      :not_an_integer)], @finding_answer.errors[:answer_type]
  end
end