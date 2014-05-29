require 'test_helper'

class QuestionnaireTest < ActiveSupport::TestCase
  def setup
    set_organization

    @questionnaire = Questionnaire.find questionnaires(:questionnaire_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Questionnaire, @questionnaire
    assert_equal questionnaires(:questionnaire_one).name, @questionnaire.name
  end

  # Prueba la creación de un cuestionario
  test 'create' do
    assert_difference ['Questionnaire.count', 'Question.count'] do
      Questionnaire.list.create(
        :name => 'Cuestionario de prueba',
        :organization_id => organizations(:cirope).id,
        :email_subject => "email@subject.com",
        :email_text => "Email text",
        :email_link => "Email link",
        :questions_attributes => {
          '1' => {
            :question => "Cuestion multi choice",
            :sort_order => 1,
            :answer_type => 1
          }
        }
      )
    end
  end

  # Prueba de actualización de un cuestionario
  test 'update' do
    assert @questionnaire.update(:name => 'Updated name'),
    @questionnaire.errors.full_messages.join('; ')
    @questionnaire.reload
    assert_equal 'Updated name', @questionnaire.name
  end

  # Prueba de eliminación de un cuestionario
  test 'delete' do
    assert_difference 'Questionnaire.count', -1 do
      assert_difference 'Question.count', -2 do
        assert_difference 'AnswerOption.count', -5 do
          @questionnaire.destroy
        end
      end
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @questionnaire.name = '  '
    @questionnaire.email_subject = '  '
    @questionnaire.email_text = '  '
    @questionnaire.email_link = '  '
    @questionnaire.organization = nil

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :blank
    assert_error @questionnaire, :email_subject, :blank
    assert_error @questionnaire, :email_text, :blank
    assert_error @questionnaire, :email_link, :blank
    assert_error @questionnaire, :organization_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @questionnaire.name = 'abcde' * 52
    @questionnaire.email_subject = 'abcde' * 52
    @questionnaire.email_text = 'abcde' * 52
    @questionnaire.email_link = 'abcde' * 52
    @questionnaire.email_clarification = 'abcde' * 52

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :too_long, count: 255
    assert_error @questionnaire, :email_subject, :too_long, count: 255    
    assert_error @questionnaire, :email_text, :too_long, count: 255
    assert_error @questionnaire, :email_link, :too_long, count: 255
    assert_error @questionnaire, :email_clarification, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @questionnaire.name = questionnaires(:questionnaire_two).name

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :taken
  end
end
