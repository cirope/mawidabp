require 'test_helper'

class QuestionnaireTest < ActiveSupport::TestCase
  setup do
    set_organization

    @questionnaire = questionnaires :questionnaire_one
  end

  test 'create' do
    assert_difference ['Questionnaire.count', 'Question.count'] do
      Questionnaire.list.create(
        name: 'Cuestionario de prueba',
        organization_id: organizations(:cirope).id,
        email_subject: 'email@subject.com',
        email_text: 'Email text',
        email_link: 'Email link',
        questions_attributes: {
          '1' => {
            question: 'Cuestion multi choice',
            sort_order: 1,
            answer_type: 1
          }
        }
      )
    end
  end

  test 'update' do
    assert @questionnaire.update(name: 'Updated name'),
    @questionnaire.errors.full_messages.join('; ')

    assert_equal 'Updated name', @questionnaire.name
  end

  test 'delete' do
    assert_difference 'Questionnaire.count', -1 do
      assert_difference 'Question.count', -@questionnaire.questions.count do
        assert_difference 'AnswerOption.count', -@questionnaire.answer_options.count do
          @questionnaire.destroy
        end
      end
    end
  end

  test 'validates blank attributes' do
    @questionnaire = Questionnaire.new name: '  ', email_subject: ''

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :blank
    assert_error @questionnaire, :email_subject, :blank
    assert_error @questionnaire, :email_text, :blank
    assert_error @questionnaire, :email_link, :blank
    assert_error @questionnaire, :organization, :blank
  end

  test 'validates length of attributes' do
    @questionnaire.name =
      @questionnaire.email_subject =
      @questionnaire.email_link = 'abcde' * 52

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :too_long, count: 255
    assert_error @questionnaire, :email_subject, :too_long, count: 255
    assert_error @questionnaire, :email_link, :too_long, count: 255
  end

  test 'validates unique attributes' do
    @questionnaire.name = questionnaires(:questionnaire_two).name

    assert @questionnaire.invalid?
    assert_error @questionnaire, :name, :taken
  end

  test 'clone from other questionnaire' do
    cloned = Questionnaire.new
    cloned.clone_from @questionnaire
    cloned.name += ' cloned' # unique name

    assert_difference 'Questionnaire.count' do
      assert_difference 'Question.count', @questionnaire.questions.count do
        assert_difference 'AnswerOption.count', @questionnaire.answer_options.count do
          cloned.save
        end
      end
    end

    cloned.reload
    %i(
      organization_id pollable_type email_text email_link email_subject
      email_clarification
    ).each do |attr|
      assert_equal @questionnaire.send(attr).to_s, cloned.send(attr).to_s, attr
    end
  end
end
