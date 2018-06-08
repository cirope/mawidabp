require 'test_helper'

class QuestionnairesControllerTest < ActionController::TestCase
  setup do
    @questionnaire = questionnaires :questionnaire_one

    login
  end

  test 'list questionnaires' do
    get :index
    assert_response :success
    assert_not_nil assigns(:questionnaires)
    assert_template 'questionnaires/index'
  end

  test 'show questionnaire' do
    get :show, params: { id: @questionnaire }
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_template 'questionnaires/show'
  end

  test 'new questionnaire' do
    get :new
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_template 'questionnaires/new'
  end

  test 'create questionnaire' do
    assert_difference 'Questionnaire.count' do
      assert_difference 'Question.count', 2 do
        assert_difference 'AnswerOption.count', Question::ANSWER_OPTIONS.size do
          post :create, params: {
            questionnaire: {
              name: 'Nuevo cuestionario',
              email_text: 'Email text',
              email_link: 'Email link',
              email_subject: 'Email subject',
              questions_attributes: [
                {
                  question: 'Cuestion multi choice',
                  sort_order: 1,
                  answer_type: 1
                }, {
                  question: 'Cuestion written',
                  sort_order: 2,
                  answer_type: 0
                }
              ]
            }
          }
        end
      end
    end
    assert_redirected_to questionnaire_path(assigns(:questionnaire))
  end

  test 'edit questionnaire' do
    get :edit, params: { id: @questionnaire }
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_template 'questionnaires/edit'
  end

  test 'update questionnaire' do
    assert_no_difference ['Questionnaire.count', 'Question.count'] do
      patch :update, params: {
        id: @questionnaire,
        questionnaire: {
          name: 'Cuestionario actualizado',
          questions_attributes: [
            {
              id: questions(:question_multi_choice).id,
              question: 'Cuestion updated',
              sort_order: 1,
              answer_type: 1,
            }
          ]
        }
      }
    end

    assert_not_nil assigns(:questionnaire)
    assert_redirected_to questionnaire_path(assigns(:questionnaire))
    assert_equal 'Cuestionario actualizado', assigns(:questionnaire).name
    assert_equal 'Cuestion updated', Question.find(
      questions(:question_multi_choice).id).question
    end

  test 'destroy questionnaire' do
    assert_difference ['Questionnaire.count'], -1 do
      assert_difference 'Question.count', -@questionnaire.questions.count do
        assert_difference ['AnswerOption.count'], -Question::ANSWER_OPTIONS.size do
          delete :destroy, params: { id: @questionnaire }
        end
      end
    end
    assert_redirected_to questionnaires_url
  end
end
