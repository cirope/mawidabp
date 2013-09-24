# encoding: utf-8
require 'test_helper'

class QuestionnaireTest < ActiveSupport::TestCase
  def setup
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
      Questionnaire.create(
        :name => 'Cuestionario de prueba',
        :organization_id => organizations(:default_organization).id,
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
    @questionnaire.organization = nil
    assert @questionnaire.invalid?
    assert_equal 2, @questionnaire.errors.count
    assert_equal [error_message_from_model(@questionnaire, :name, :blank)],
      @questionnaire.errors[:name]
    assert_equal [error_message_from_model(@questionnaire, :organization_id, :blank)],
      @questionnaire.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @questionnaire.name = 'abcde' * 52
    assert @questionnaire.invalid?
    assert_equal 1, @questionnaire.errors.count
    assert_equal [error_message_from_model(@questionnaire, :name, :too_long,
      :count => 255)], @questionnaire.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @questionnaire.name = questionnaires(:questionnaire_two).name
    assert @questionnaire.invalid?
    assert_equal 1, @questionnaire.errors.count
    assert_equal [error_message_from_model(@questionnaire, :name, :taken)],
      @questionnaire.errors[:name]
  end
end
