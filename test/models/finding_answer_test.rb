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
    assert_equal fixture_finding_answer.commitment_date,
      @finding_answer.commitment_date
    assert_equal fixture_finding_answer.finding_id, @finding_answer.finding_id
    assert_equal fixture_finding_answer.user_id, @finding_answer.user_id
    assert_equal fixture_finding_answer.file_model_id,
      @finding_answer.file_model_id
  end

  # Prueba la creación de una respuesta a una observación
  test 'auditor create without notification' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          :answer => 'New answer',
          :auditor_comments => 'New auditor comments',
          :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          :user => users(:administrator_user),
          :file_model => file_models(:text_file),
          :notify_users => false
        )
      end
    end
  end

  # Prueba la creación de una respuesta a una observación
  test 'audited create without notification' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          :answer => 'New answer',
          :commitment_date => 10.days.from_now.to_date,
          :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          :user => users(:audited_user),
          :file_model => file_models(:text_file),
          :notify_users => false
        )
      end
    end
  end

  # Prueba la creación de una respuesta a una observación
  test 'auditor create with notification' do
    counts_array = ['FindingAnswer.count', 'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      @finding_answer = FindingAnswer.create(
        :answer => 'New answer',
        :auditor_comments => 'New auditor comments',
        :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
        :user => users(:administrator_user),
        :file_model => file_models(:text_file),
        :notify_users => true
      )
    end
  end

  # Prueba la creación de una respuesta a una observación
  test 'audited create with notification' do
    counts_array = ['FindingAnswer.count', 'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      @finding_answer = FindingAnswer.create(
        :answer => 'New answer',
        :commitment_date => 10.days.from_now.to_date,
        :finding => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
        :user => users(:audited_user),
        :file_model => file_models(:text_file),
        :notify_users => true
      )
    end
  end

  # Prueba de actualización de una respuesta a una observación
  test 'update' do
    assert @finding_answer.update(:answer => 'New answer'),
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
  test 'validates blank attributes with auditor' do
    @finding_answer.answer = '      '
    @finding_answer.finding_id = nil
    @finding_answer.commitment_date = ''

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :finding_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes with audited' do
    @finding_answer.user = users(:audited_user)
    @finding_answer.answer = '      '
    @finding_answer.finding = findings(:iso_27000_security_policy_3_1_item_weakness)
    @finding_answer.commitment_date = ''

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :commitment_date, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @finding_answer.finding_id = '?nil'
    @finding_answer.user_id = '?123'
    @finding_answer.file_model_id = 'incorrect'
    @finding_answer.commitment_date = '13/13/13'

    assert @finding_answer.invalid?
    assert_error @finding_answer, :finding_id, :not_a_number
    assert_error @finding_answer, :user_id, :not_a_number
    assert_error @finding_answer, :file_model_id, :not_a_number
    assert_error @finding_answer, :commitment_date, :invalid_date
  end
end
